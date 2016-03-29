import UIKit
import AVFoundation
import Foundation
import Alamofire
import CoreData
import Reachability

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    var userName:String?
    
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
            
            view.bringSubviewToFront(messageLabel)
            
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
            messageLabel.text = "Não foi detectado nenhum QR Code"
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedBarCodes.contains(metadataObj.type) {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.text = metadataObj.stringValue
                self.captureSession?.stopRunning()
                
                let reach:Reachability
                do {
                    reach = try Reachability.reachabilityForInternetConnection()
                }
                catch {
                    fatalError("\(error)")
                }
                
                if reach.isReachableViaWiFi() {
                    validateRider(metadataObj.stringValue)
                }
                else {
                    offlineValidateRider(metadataObj.stringValue)
                }
            }
        }
    }


    
    
    func validateRider (qrcode: String) -> Void {
        
        if (qrcode.isEmpty) {
            return
        }

        Alamofire.request(.GET, "http://Ruis-MBP.local:3000/validateRider/\(qrcode)")
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                    
                    let r = JSON as! NSDictionary
                    
                    let alert = UIAlertController(title: "Provas BTT", message: "O atleta \(r.objectForKey("name") as! String) foi validado", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                        (action: UIAlertAction!) in
                        self.captureSession?.startRunning()
                        alert.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                }
                
                
            
        }
    }
    
    
    func offlineValidateRider (qrcode:String) -> Void {
     
        let moc = DataController().managedObjectContext
        let entity = NSEntityDescription.insertNewObjectForEntityForName("Race", inManagedObjectContext: moc) as! Race
       
        let time = NSDate().timeIntervalSince1970.description
        
        entity.setValue(qrcode, forKey: "qrcode")
        entity.setValue(time, forKey: "validated")
     
        do {
           try moc.save()
        }
        catch {
            fatalError("Failure to save context: \(error)")
        }
        
        self.captureSession?.startRunning()
        
    }
    
    
    
        
    
    
    func showData () {
        
        let fetch = NSFetchRequest(entityName: "Race")
        
        do {
            let req =  try moc.executeFetchRequest(fetch) as! [Race]
            
            for record in req {
                print ("\(record.qrcode!) + \(record.validated) + \(record.check1) + \(record.check2) + \(record.final)" )
            }
            print (req.count)
        }
        catch {
            fatalError("\(error)")
        }
        
        
    }
    
    
    
    
    
}
