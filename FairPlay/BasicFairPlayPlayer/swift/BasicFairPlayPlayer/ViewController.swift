//
//  ViewController.swift
//  BasicFairPlayPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit

// Add your Brightcove account and video information here.
// The video should be encrypted with FairPlay
let kViewControllerVideoCloudAccountId = "5434391461001"
let kViewControllerVideoCloudPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kViewControllerVideoId = "6140448705001"

// If you are using Dynamic Delivery you don't need to set these
let kViewControllerFairPlayApplicationId = ""
let kViewControllerFairPlayPublisherId = ""


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {
    let playbackService = BCOVPlaybackService(accountId: kViewControllerVideoCloudAccountId, policyKey: kViewControllerVideoCloudPolicyKey)
    var fairPlayAuthProxy: DRMLiveFPSAuthProxy?
    var playbackController :BCOVPlaybackController?
    @IBOutlet weak var videoContainerView: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if kViewControllerVideoCloudAccountId == ""
        {
            print("\n***** WARNING *****")
            print("Remember to add your account credentials at the top of ViewController.swift")
            print("***** WARNING *****")
            return
        }
        
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        
        // This shows the two ways of using the Brightcove FairPlay session provider:
        // Set to true for Dynamic Delivery; false for a legacy Video Cloud account
        let using_dynamic_delivery = false
        
        if (( using_dynamic_delivery ))
        {
            // If you're using Dynamic Delivery, you don't need to load
            // an application certificate. The FairPlay session will load an
            // application certificate for you if needed.
            // You can just load and play your FairPlay videos.
            
            // If you are using Dynamic Delivery, you can pass nil for the publisherId and applicationId,
//            self.fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil,
//                                                                applicationId: nil)
            self.fairPlayAuthProxy = DRMLiveFPSAuthProxy(token: token)

            // Create chain of session providers
            let psp = sdkManager?.createBasicSessionProvider(with:nil)
            let fps = sdkManager?.createFairPlaySessionProvider(withApplicationCertificate:nil,
                                                                authorizationProxy:self.fairPlayAuthProxy!,
                                                                upstreamSessionProvider:psp)
            
            // Create the playback controller
            let playbackController = sdkManager?.createPlaybackController(with:fps, viewStrategy:nil)
            
            playbackController?.isAutoAdvance = false
            playbackController?.isAutoPlay = true
            playbackController?.delegate = self
            
            if let _view = playbackController?.view {
                _view.translatesAutoresizingMaskIntoConstraints = false
                videoContainerView.addSubview(_view)
                NSLayoutConstraint.activate([
                    _view.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
                    _view.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
                    _view.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
                    _view.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
                ])
            }
            
            self.playbackController = playbackController
            
            self.requestContentFromPlaybackService()
            self.createPlayerView()
        }
        else
        {
            // Legacy Video Cloud account
            
            // You can create your FairPlay session provider first, and give it an
            // application certificate later, but in this application we want to play
            // right away, so it's easier to load our player as soon as we know
            // that we have an application certificate.
            
            // Retrieve application certificate using the FairPlay auth proxy
//            self.fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: kViewControllerFairPlayPublisherId,
//                                                                applicationId: kViewControllerFairPlayApplicationId)
            self.fairPlayAuthProxy = DRMLiveFPSAuthProxy(token: token)
//            print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: fairPlayAuthProxy = \(fairPlayAuthProxy).");
            
            self.fairPlayAuthProxy?.getApplicationCertificate() { [weak self] (applicationCertificate: Data?, error: Error?) -> Void in
                guard let appCert = applicationCertificate else
                {
                    print("ViewController Debug - Error retrieving app certificate: %@", error!)
                    return
                }
//                print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: app certificate = \(applicationCertificate?.count).");
                
                guard let strongSelf = self else {
                    return
                }
                
                // Create chain of session providers
                let psp = sdkManager?.createBasicSessionProvider(with:nil)
//                print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: BasicSessionProvider = \(psp).");
//                print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: fairPlayAuthProxy = \(strongSelf.fairPlayAuthProxy).");
                
                let fps = sdkManager?.createFairPlaySessionProvider(withApplicationCertificate:appCert,
                                                                    authorizationProxy:strongSelf.fairPlayAuthProxy!,
                                                                    upstreamSessionProvider:psp)
//                print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: FPS provider = \(fps).");
                
                DispatchQueue.main.async{
                    // Create the playback controller
                    let playbackController = sdkManager?.createPlaybackController(with:fps, viewStrategy:nil)
//                    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: playbackController = \(playbackController).");
                    
                    playbackController?.isAutoAdvance = false
                    playbackController?.isAutoPlay = true
                    playbackController?.delegate = self
                    

                    if let _view = playbackController?.view {
                        _view.translatesAutoresizingMaskIntoConstraints = false
                        strongSelf.videoContainerView.addSubview(_view)
                        NSLayoutConstraint.activate([
                            _view.topAnchor.constraint(equalTo: strongSelf.videoContainerView.topAnchor),
                            _view.rightAnchor.constraint(equalTo: strongSelf.videoContainerView.rightAnchor),
                            _view.leftAnchor.constraint(equalTo: strongSelf.videoContainerView.leftAnchor),
                            _view.bottomAnchor.constraint(equalTo: strongSelf.videoContainerView.bottomAnchor)
                        ])
                        print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: views are all set.");
                    }

                    strongSelf.playbackController = playbackController
                    
                    strongSelf.playLiveByUrl()
//                    strongSelf.requestContentFromPlaybackService()
                    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: playLiveByUrl()");
                    
                    strongSelf.createPlayerView()
                    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: create player view");
                }
            }
        }
    }
    // this token is generdated by lxp layer
    let token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJjcnQiOiJbe1wiYWNjb3VudGluZ0lkXCI6XCJOaW5lSWRlbnRpdHlBY2NvdW50XCIsXCJhc3NldElkXCI6XCJHRU1IRFNZRFwiLFwicHJvZmlsZVwiOntcInJlbnRhbFwiOntcImFic29sdXRlRXhwaXJhdGlvblwiOlwiMjAyMy0wMS0wMVQwMDowMDowMC4wMDBaXCIsXCJwbGF5RHVyYXRpb25cIjo2MDAwMDB9fSxcIm91dHB1dFByb3RlY3Rpb25cIjp7XCJkaWdpdGFsXCI6ZmFsc2UsXCJhbmFsb2d1ZVwiOmZhbHNlLFwiZW5mb3JjZVwiOmZhbHNlfX1dIiwib3B0RGF0YSI6IntcInVzZXJJZFwiOlwiNjc4Y2VmYTU3ZjcxNGIwNjg4NjgyMTE2ZGM0OWVlMGJcIixcIm1lcmNoYW50XCI6XCJuaW5lX2F1MlwiLFwic2Vzc2lvbklkXCI6XCJleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSXNJbXRwWkNJNklqRTJNamRpTWpWak1XRTFORGt5TlRReU1EQXhaamsxWXpJell6STBabUV5SW4wLmV5SnVkV2xrSWpvaU5qYzRZMlZtWVRVM1pqY3hOR0l3TmpnNE5qZ3lNVEUyWkdNME9XVmxNR0lpTENKaGNHbGtJam9pWVRSbVlqZ3lPV1l0TlRJeFl5MDNaakZtTFRWbVl6TXRNekJsTUdRNVpEQTNPREl6SWl3aWMyTnZjR1VpT2lKdmNHVnVhV1FnZFhObGNtbHVabTg2WVd4c0lHOW1abXhwYm1WZllXTmpaWE56SWl3aWFXRjBJam94TmpRMU5ESXdNVE0xTENKbGVIQWlPakUyTkRVME1qQTBNelVzSW1GMVpDSTZJamx1YjNjdGNtNHRhVzl6TFhWaGRDSXNJbWx6Y3lJNkltaDBkSEJ6T2k4dmRXRjBMbXh2WjJsdUxtNXBibVV1WTI5dExtRjFJaXdpYzNWaUlqb2lOamM0WTJWbVlUVTNaamN4TkdJd05qZzROamd5TVRFMlpHTTBPV1ZsTUdJaWZRLk4xcUJ0X0NBclRuOWkyMkZvbWV4Y3BMd29ZbXZtTlJCZDNrZXg1ajVEeEg4QnFvbzBQTGxLM0luenpHNDlRNElUakpvbGVLT0JQR1ZiU3VJWExuV0hIMmpWNkFFUHVvbjFtNi1jbFBRS2NyRU91a3g4bVhYV1JJekJ3eUpFOTItM3I0MGJvRWhzbUNOMFVGMnliSk5wbXB2b3E3V2hDbGlYOWNaN0RJczExY2JqMl9MZDZhTHFKNTNFQWZIOEpvdWlPUnVKaldGdDl3REtSM3hxMXZheS1hX0w2TFJHcUczbEQ3ZG9aUWc3eTJFTHVqV1ZFRUp0Vm5Gcnk5Qnh0SURYRERuMjd3ek9QUmhDeU5QSXhoQUdkU2lnSWZCTW5TRmtMMEo4TDZ3cDdMV3hhSmp0b2dhRklBNUdRYUpzTlNUUHhBNXZVTzNPUVgweXFuWFVZNkhsZ1wifSIsImp0aSI6ImVjOTg1MzViLWZmYTgtNDc0Yy04YTdmLWJhODg4NWZkYWM2NiIsImlhdCI6MTY0NTQyMDIwNSwiZXhwIjoxNjQ1NDIwODA1LCJhdWQiOiJEUk10b2RheSIsImlzcyI6Imh0dHBzOi8vdWF0LmxvZ2luLm5pbmUuY29tLmF1In0.zka5lAcXEoTvkY4_j_M4lKCui_YTgQ86yOEdMT--Gg6mgDaltqOKn6d3Pm_Z-wR-Djxh6dzpomhMMv3VjtNaKg"
    let accountId = "4468173393001"
    let brightcoveId = "6256350766001" // "6237075657001", "6269688296001"
    let name = "MyShow"
    
    
    func playLiveByUrl() {
//      let drmUrl = "https://d2ngup2zqyjdr.cloudfront.net/out/v1/f33f0b48e12c41ddb67ccd4d36650198/index.m3u8"
      let drmUrl = "https://d2ngup2zqyjdr.cloudfront.net/out/v1/4ca6d8a7c32f477cb7058522efb13bd0/CMAF_HLS/index.m3u8";
//      let drmUrl = "https://d2ngup2zqyjdr.cloudfront.net/out/v1/83d26ed41e5a432c96579a8d0c965213/CMAF_HLS/index.m3u8" // clear
      let source = BCOVSource(url: URL(string: drmUrl), deliveryMethod: kBCOVSourceDeliveryHLS, properties: nil)
      print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: playLiveByUrl(), Url = \(drmUrl).");
      
        let video = BCOVVideo(source: source, cuePoints: nil, properties: ["accountId": accountId, "id": brightcoveId, "name": name])
      print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: playLiveByUrl(), video = \(video).");
      
//          self.load(videos: [_video])
      self.playbackController!.setVideos([ video ] as NSArray)
        
        // self.playbackController?.play()
//      if let _video = video {
//      }
    }

    
    func requestContentFromPlaybackService() {
//        playbackService?.findVideo(withVideoID:kViewControllerVideoId, parameters: nil) { (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
//            if video == nil
//            {
//                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
//                return
//            }
//
//            self.playbackController!.setVideos([ video! ] as NSArray)
//        }
    }
    
    // Create the player view
    func createPlayerView() {
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        guard let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: nil, controlsView: controlView) else {
            return
        }
        videoContainerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            playerView.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
            ])
        
        playerView.playbackController = self.playbackController
    }
    
    func playbackController(_: BCOVPlaybackController!, didAdvanceTo: BCOVPlaybackSession!) {
        print("ViewController Debug: Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: playback event = \(lifecycleEvent.eventType)");

        // Report any errors that may have occurred with playback.
        if (kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType)
        {
            let error = lifecycleEvent.properties["error"] as! NSError
            print("Playback error: \(error.localizedDescription)")
        }
    }
}


class DRMLiveFPSAuthProxy : NSObject, BCOVFPSAuthorizationProxy {

  
  var authToken: String = ""

  init(token: String){
    authToken = token
    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: DRMLiveFPSAuthProxy init() !!!!!!");
  }

  func getApplicationCertificate(completionHandler: @escaping (Data?, Error?) -> Void) {
    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: getApplicationCertificate");
    // send http get Certificate Request¶
    // Document is: https://fe.staging.drmtoday.com/documentation/integration/player/fairplay.html
    // https://lic.staging.drmtoday.com/license-server-fairplay/cert/nine_au

    
    let session = URLSession(configuration: .default)
    // set url
    let UrlRequest = URLRequest(url: URL(string: "https://lic.staging.drmtoday.com/license-server-fairplay/cert/nine_au")!)
    // create netowrk session
    let task = session.dataTask(with: UrlRequest) {(data, response, error) in
      print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: getApplicationCertificate data = \(data), error = \(error)");
      completionHandler(data, error)
    }
    task.resume()
  }
  
  func contentIdentifier(from loadingRequest: AVAssetResourceLoadingRequest) -> Data? {
      print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: contentIdentifier()");
    // extract the content id from the skd://xxxxx from the manifest(m3u8)
    // skd://drmtoday?assetId=9-Syd-Ateme&variantId=&keyId=578fff5d1e30414797842119b69848dd&keyRotationId=0
    let urlString = loadingRequest.request.url?.absoluteString ?? ""
    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: contentIdentifier url = \(urlString)");

    let urlComponents = URLComponents(string: urlString)
    let id = urlComponents?.queryItems?.first(where: {$0.name == "keyId"})?.value ?? ""
    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: contentIdentifier keyId = \(id)");

//    let result = urlString.components(separatedBy: "&")
//    let a = result.reduce(into: [String: String]()) { (result, item) in
//        if item.contains("assetId") {
//            let rslt = item.components(separatedBy: "=")
//            result[rslt[0]] = rslt[1]
//            print("result = \(result)")
//        }
//    }

    return Data.init(base64Encoded: id)
  }
  
  func encryptedContentKey(forContentKeyIdentifier contentKeyIdentifier: String, contentKeyRequest keyRequest: Data, source: BCOVSource, options: [AnyHashable : Any]? = nil, completionHandler: @escaping (URLResponse?, Data?, Date?, Error?) -> Void) {

    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: encryptedContentKey");
    let session = URLSession(configuration: .default)
    
    let urlEncodedKeyRequest = keyRequest.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    let url = URL(string: "https://lic.staging.drmtoday.com/license-server-fairplay?spc=\(urlEncodedKeyRequest)")

    print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: encryptedContentKey, url = \(url), authToken = \(authToken)");

    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.addValue("x-dt-auth-token", forHTTPHeaderField: authToken)
    
    let task = session.dataTask(with: request) {(data, response, error) in
      print("🚒 [\(Date().description(with: Locale.current))] Hai-drm: encryptedContentKey completed, response = \(response), data = \(data)");
      completionHandler(response, data, nil, error)
    }
    task.resume()
  }
 }
