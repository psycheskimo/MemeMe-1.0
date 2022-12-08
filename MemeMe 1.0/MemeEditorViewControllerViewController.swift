//
//  MemeEditorViewController.swift
//  MemeMe 1.0
//
//  Created by Can Yıldırım on 3.12.2022.
//

import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{
    
    
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var toolBarTop : UIToolbar!
    @IBOutlet weak var toolBarBottom : UIToolbar!
    @IBOutlet weak var shareButton : UIBarButtonItem!
    @IBOutlet weak var cancelButton : UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.darkGray
        prepareTextField(textField: topTextField, defaultTextField: "TOP")
        prepareTextField(textField: bottomTextField, defaultTextField: "BOTTOM")
        imagePickerView.contentMode = .scaleAspectFit
        topTextField.borderStyle = .none
        bottomTextField.borderStyle = .none
        shareButton.isEnabled = false
        cancelButton.isEnabled = false

        let memeTextAttributes : [NSAttributedString.Key : Any] = [
            
            NSAttributedString.Key.strokeColor : UIColor.black,
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedString.Key.strokeWidth : -3.5
       
        ]
     
        topTextField.defaultTextAttributes = memeTextAttributes
        bottomTextField.defaultTextAttributes = memeTextAttributes
        
    }
    
    
    func prepareTextField(textField: UITextField, defaultTextField: String) {
        
        textField.text = defaultTextField
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if targetEnvironment(simulator)
        cameraButton.isEnabled = false
        #else
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        #endif
        
        subscribeToKeyboardNotification()
        subscribeToKeyboardNewNotification()
        topTextField.textAlignment = .center
        bottomTextField.textAlignment = .center
     
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeToKeyboardNotification()
        unsubscribeToKeyboardNewNotification()
        
    }
   
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        
        prepareTextField(textField: topTextField, defaultTextField: "TOP")
        prepareTextField(textField: bottomTextField, defaultTextField: "BOTTOM")
        imagePickerView.image = .none
        cancelButton.isEnabled = false
        
    }
    
    
    @IBAction func pickAnImage(_ sender: UIBarButtonItem) {
        
        pickImage(sourceType: .photoLibrary)

    }
    
    @IBAction func pickAnImageFromCamera(_ sender: UIBarButtonItem) {

        pickImage(sourceType: .camera)
        
    }

    func pickImage(sourceType: UIImagePickerController.SourceType) {
        
        let pickerControl = UIImagePickerController()
        pickerControl.delegate = self
        present(pickerControl, animated: true, completion: nil)

    }
    
    struct Meme {
        
        var topText : String
        var bottomText : String
        var originalImage : UIImage
        var memedImage : UIImage
        
    }
    
    func save() {
        
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imagePickerView.image!, memedImage: generateMemedImage())
     
    }
    
    func generateMemedImage() -> UIImage {
        
        toolBarBottom.isHidden = true
        toolBarTop.isHidden = true
        
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        toolBarTop.isHidden = false
        toolBarBottom.isHidden = false
   
        return memedImage
       
    }
    
    @IBAction func activityView(_ sender: UIBarButtonItem) {
        
        let memedImage = generateMemedImage()
        
        let controller = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        present(controller, animated: true, completion: nil)
        
        controller.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in

            guard completed != false else {return}

            if let activity = activityType {

                switch activity {

                case .saveToCameraRoll :
                    
                    self.save()
                    self.alertControl(title: "", message: "Image has been saved!", prefferredStyle: UIAlertController.Style.alert, actionTitle: "OK", actionStyle: UIAlertAction.Style.default)
                    
                default : return

                }

            }

        }
    
    }

    func alertControl(title: String, message: String, prefferredStyle: UIAlertController.Style, actionTitle: String, actionStyle: UIAlertAction.Style) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: prefferredStyle)
        let actionAlert = UIAlertAction(title: actionTitle, style: actionStyle, handler: nil)
        alertController.addAction(actionAlert)
        self.present(alertController, animated: true, completion: nil)
     
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            imagePickerView.image = image
            
        }
        
        dismiss(animated: true, completion: nil)
        shareButton.isEnabled = true
        
    }

    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if topTextField.isEditing {
            
            topTextField.text = ""
            
        } else {
            
            bottomTextField.text = ""
            
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        cancelButton.isEnabled = true
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
        
    }
    
    @objc func keyboardWillShow(_ notification : Notification) {
        
        if topTextField.isEditing {
       
        view.frame.origin.y = -getKeyboardHeight(notification)
        view.frame.origin.y = -topTextField.frame.height
        
        } else {
        
        view.frame.origin.y = -getKeyboardHeight(notification)
            
        }
        
    }
   
    @objc func keyboardWillHide(_ notification : Notification) {
        
        view.frame.origin.y = 0
        
    }
    
    func getKeyboardHeight(_ notification : Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
        
    }
    
    func subscribeToKeyboardNotification() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification , object: nil)
    }
    
    func unsubscribeToKeyboardNotification() {
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        
    }
    
    func subscribeToKeyboardNewNotification() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNewNotification() {
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}


