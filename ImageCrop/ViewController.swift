//
//  ViewController.swift
//  ImageCrop
//
//  Created by 天明 on 2018/7/12.
//  Copyright © 2018年 天明. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        PHPhotoLibrary.requestAuthorization { (status) in
            print(status)
        }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let original = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        var config = ImageCropConfig()
        config.cropRate = 3/4
        config.borderWidth = 2
        config.edge = 16
        let cropVC = ImageCropVC(image: original, config: config)
        cropVC.success = { [unowned self] image in
            self.imageView.image = image
        }
        picker.pushViewController(cropVC, animated: true)
    }

}
