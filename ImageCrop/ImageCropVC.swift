//
//  ImageCropVC.swift
//  test
//
//  Created by 天明 on 2018/7/11.
//  Copyright © 2018年 天明. All rights reserved.
//

import UIKit
import SnapKit

let screenBounds = UIScreen.main.bounds
class ImageCropVC: UIViewController {
    
    let originalImage: UIImage
    let config: ImageCropConfig
    public var success: ((UIImage) -> Void)?
    public var cancel: (() -> Void)?
    
    var customView: ImageCropView!
    
    init(image: UIImage, config: ImageCropConfig = ImageCropConfig()) {
        self.originalImage = image
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        customView = ImageCropView(image: originalImage, config: config)
        view.addSubview(customView)
        customView.cancel = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        customView.completion = { [weak self] image in
            if let _img = image {
                self?.success?(_img)
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }else {
                print("错误")
            }
        }
    }

}


