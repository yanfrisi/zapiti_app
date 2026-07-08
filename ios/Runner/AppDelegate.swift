import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioPlayer: AVAudioPlayer?
  private var currentAsset: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "zapiti/music",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(nil)
          return
        }

        switch call.method {
        case "play":
          let args = call.arguments as? [String: Any]
          guard let asset = args?["asset"] as? String else {
            result(nil)
            return
          }
          let volume = args?["volume"] as? Double ?? 0.65
          self.play(asset: asset, volume: Float(volume))
          result(nil)
        case "setVolume":
          let args = call.arguments as? [String: Any]
          let volume = args?["volume"] as? Double ?? 0.65
          self.setVolume(Float(volume))
          result(nil)
        case "stop":
          self.stop()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func play(asset: String, volume: Float) {
    let clampedVolume = min(max(volume, 0), 1)

    if currentAsset == asset, let player = audioPlayer {
      player.volume = clampedVolume
      player.play()
      return
    }

    stop()

    let assetKey = FlutterDartProject.lookupKey(forAsset: asset)
    guard let path = Bundle.main.path(forResource: assetKey, ofType: nil) else {
      return
    }

    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
      player.numberOfLoops = -1
      player.volume = clampedVolume
      player.prepareToPlay()
      player.play()
      audioPlayer = player
      currentAsset = asset
    } catch {
      stop()
    }
  }

  private func setVolume(_ volume: Float) {
    audioPlayer?.volume = min(max(volume, 0), 1)
  }

  private func stop() {
    audioPlayer?.stop()
    audioPlayer = nil
    currentAsset = nil
  }
}
