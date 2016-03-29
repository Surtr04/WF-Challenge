import UIKit
import AVFoundation
import Alamofire
import CoreData
import Reachability

class ViewController2: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var messageLabel2: UILabel!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    let moc = DataController().managedObjectContext
    
    let supportedBarCodes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeAztecCode]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
                        
        
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            
            captureMetadataOutput.metadataObjectTypes = supportedBarCodes
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            view.bringSubviewToFront(messageLabel2)
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.greenColor().CGColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
            
        } catch {
            print(error)
            return
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRectZero
            messageLabel2.text = "Não foi detectado nenhum QR Code"
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedBarCodes.contains(metadataObj.type) {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel2.text = metadataObj.stringValue
                self.captureSession?.stopRunning()
                
                
                let reach:Reachability
                do {
                    reach = try Reachability.reachabilityForInternetConnection()
                }
                catch {
                    fatalError("\(error)")
                }

                
                if reach.isReachableViaWiFi() {
                    setTime(metadataObj.stringValue)
                }
                else {
                    offlineSetTime(metadataObj.stringValue)
                }
            }
        }
    }
    
    
    func setTime (qrcode: String) -> Void {
        
        if (qrcode.isEmpty) {
            return
        }
        
        
        Alamofire.request(.GET, "http://Ruis-MBP.local:3000/setTime/\(qrcode)")
            .responseJSON { response in                
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                    
                    let r = JSON as! NSDictionary
                    
                    if (r.objectForKey("validated") as! String) == "true" {
                    
                        let alert = UIAlertController(title: "Provas BTT", message: "O tempo do atleta \(r.objectForKey("name") as! String) foi contabilizado", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                            (action: UIAlertAction!) in
                            alert.dismissViewControllerAnimated(true, completion: nil)
                            self.captureSession?.startRunning()
                        }))
                        self.presentViewController(alert, animated: true, completion: nil)
                    
                    }
                    
                    else {
                        
                        let alert = UIAlertController(title: "Provas BTT", message: "O atleta \(r.objectForKey("name") as! String) não foi validado", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                            (action: UIAlertAction!) in
                            alert.dismissViewControllerAnimated(true, completion: nil)
                            self.captureSession?.startRunning()
                        }))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    
                }
                
        }
    
    }
    
    
    func offlineSetTime (qrcode:String) -> Void {
        
        let fetch = NSFetchRequest(entityName: "Race")
        
        
        do {
            fetch.predicate = NSPredicate(format: "qrcode == %@", qrcode)
            let req =  try moc.executeFetchRequest(fetch) as! [Race]
            
            let req2 = req.first
            
            if ((req2!.check1?.isEmpty) != nil) {
                req2!.check1 = NSDate().timeIntervalSince1970.description
            }
            else {
                if ((req2!.check2?.isEmpty) != nil) {
                    req2!.check2 = NSDate().timeIntervalSince1970.description
                }
                else {
                    if ((req2!.final?.isEmpty) != nil) {
                        req2!.final = NSDate().timeIntervalSince1970.description
                    }
                }
            }
            
                try moc.save()
            }
        catch {
            fatalError("\(error)")
        }
        
        self.captureSession?.startRunning()
    }




}

