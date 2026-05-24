import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var privilegedShell: PrivilegedShell?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let shell = PrivilegedShell()
    shell.register(with: flutterViewController.engine.binaryMessenger)
    privilegedShell = shell

    super.awakeFromNib()
  }

  deinit {
    privilegedShell?.dispose()
  }
}
