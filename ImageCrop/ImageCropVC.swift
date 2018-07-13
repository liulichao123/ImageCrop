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
    var success: ((UIImage) -> Void)?
    var cancel: (() -> Void)?
    
    var customView: ImageCropView!
    var cancelButton: UIButton!
    var comfirmButton: UIButton!
    
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
        
        cancelButton = UIButton()
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.left.equalToSuperview().offset(20)
            if #available(iOS 11.0, *) {
                $0.bottom.equalTo(self.view.safeAreaInsets).offset(-20)
            } else {
                $0.bottom.equalToSuperview().offset(-20)
            }
        }
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.addTarget(self, action: #selector(didCancel), for: .touchUpInside)
        comfirmButton = UIButton()
        view.addSubview(comfirmButton)
        comfirmButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-20)
            if #available(iOS 11.0, *) {
                $0.bottom.equalTo(self.view.safeAreaInsets).offset(-20)
            } else {
                $0.bottom.equalToSuperview().offset(-20)
            }
        }
        comfirmButton.setTitle("确认", for: .normal)
        comfirmButton.addTarget(self, action: #selector(didConfirm), for: .touchUpInside)
    }
    
     @objc func didCancel() {
        self.cancel?()
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func didConfirm() {
        if let cropImage = self.customView.getCropImage()  {
            self.success?(cropImage)
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            print("错误")
        }
    }

}


