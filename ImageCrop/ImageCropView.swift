//
//  CustomView.swift
//  test
//
//  Created by 天明 on 2018/7/12.
//  Copyright © 2018年 天明. All rights reserved.
//

import UIKit

public struct ImageCropConfig {
    public var cropRate: CGFloat = 1
    public var edge: CGFloat = 16
    public var borderColor: UIColor = UIColor.white
    public var borderWidth: CGFloat = 2
    public var minZoomScale: CGFloat = 1
    public var maxZoomScale: CGFloat = 5
    public init() { }
}

class ImageCropView: UIView {
    
    private let originalImage: UIImage
    private var config: ImageCropConfig
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var _maskView: UIView!
    
    public var cancelButton: UIButton!
    public var comfirmButton: UIButton!
    public var resetButton: UIButton!
    
    private var _rate: CGFloat = 1
    private var _able: Bool
    private var orginZoomScale: CGFloat = 1
    private var orginOffset: CGPoint = CGPoint.zero
    
    public var completion: ((UIImage?) -> Void)?
    public var cancel: (() -> Void)?
    
    init(image: UIImage, config: ImageCropConfig = ImageCropConfig()) {
        self.originalImage = image
        self.config = config
        self._able = !(image.size.width == 0 ||  image.size.height == 0)
        if _able {
            _rate = image.size.width/image.size.height
        }
        super.init(frame: UIScreen.main.bounds)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if cancelButton.frame.contains(point) {
            return cancelButton
        }
        if resetButton.frame.contains(point) {
            return resetButton
        }
        if comfirmButton.frame.contains(point) {
            return comfirmButton
        }
        return scrollView
    }
    
    private func setupViews() {
        setupScrollView()
        setupButtons()
    }
    
    private func setupScrollView() {
        let w = screenBounds.width - config.edge*2
        let h = w/config.cropRate
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        scrollView.center = self.center
        addSubview(scrollView)
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isMultipleTouchEnabled = true
        scrollView.bouncesZoom = true
        scrollView.minimumZoomScale = config.minZoomScale
        scrollView.maximumZoomScale = config.maxZoomScale
        scrollView.layer.masksToBounds = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.backgroundColor = UIColor.black
        scrollView.delegate = self
        
        scrollView.layer.borderWidth = config.borderWidth
        scrollView.layer.borderColor = config.borderColor.cgColor
        
        imageView = UIImageView(image: originalImage)
        imageView.frame = CGRect(x: 0, y: 0, width: w, height: h)
        imageView.contentMode = .scaleAspectFill
        scrollView.addSubview(imageView)
        
        var contentSize = scrollView.frame.size
        if _rate > config.cropRate {//图片宽高比例>裁剪的宽高比例时
            //需要根据裁剪框的高计算contentSize的宽
            contentSize.width = _rate*h
        } else {
            contentSize.height = w/_rate
        }
        imageView.frame.size = contentSize
        scrollView.contentSize = contentSize
        
        imageView.center = CGPoint(x: contentSize.width/2, y: contentSize.height/2)
        scrollView.setContentOffset(CGPoint(x: (contentSize.width-scrollView.frame.width)/2, y: (contentSize.height-scrollView.frame.height)/2), animated: false)
        orginOffset = scrollView.contentOffset
        
        //当图片宽度小于k高度时，让图片宽度占满屏幕
        //        if config.cropRate != 1 && _rate < 1 && w != 0 {
        //            scrollView.zoomScale = self.bounds.width/w
        //        }
        orginZoomScale = scrollView.zoomScale
        
        //中间镂空的遮罩
        _maskView = UIView(frame: self.bounds)
        _maskView.backgroundColor =  UIColor.init(white: 0.5, alpha: 0.64)
        addSubview(_maskView)
        let path = UIBezierPath(rect: self.bounds)
        path.append(UIBezierPath(rect: scrollView.frame).reversing())
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        _maskView.layer.mask = shapeLayer
        
    }
    
    private func setupButtons() {
        resetButton = UIButton()
        addSubview(resetButton)
        resetButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            if #available(iOS 11.0, *) {
                $0.bottom.equalTo(self.safeAreaInsets).offset(-20)
            } else {
                $0.bottom.equalToSuperview().offset(-20)
            }
        }
        resetButton.setTitle("还原", for: UIControl.State.normal)
        resetButton.backgroundColor = UIColor.clear
        resetButton.addTarget(self, action: #selector(self.didReset), for: .touchUpInside)
        resetButton.isEnabled = false
        
        cancelButton = UIButton()
        addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.left.equalToSuperview().offset(20)
            $0.centerY.equalTo(self.resetButton)
        }
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.backgroundColor = UIColor.clear
        cancelButton.addTarget(self, action: #selector(self.didCancel), for: .touchUpInside)
        
        comfirmButton = UIButton()
        addSubview(comfirmButton)
        comfirmButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-20)
            $0.centerY.equalTo(self.resetButton)
        }
        comfirmButton.setTitle("完成", for: .normal)
        comfirmButton.backgroundColor = UIColor.clear
        comfirmButton.addTarget(self, action: #selector(self.didConfirm), for: .touchUpInside)
    }
    
    
    public func getCropImage() -> UIImage? {
        guard _able else { return nil }
        var cropRect = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        
        let scale = max(originalImage.size.width/imageView.frame.width, originalImage.size.height/imageView.frame.height)
        cropRect.origin.x *= scale
        cropRect.origin.y *= scale
        cropRect.size.width *= scale
        cropRect.size.height *= scale
        
        guard let cropCGImage = originalImage.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropCGImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
    }
    
    func reset() {
        scrollView.setZoomScale(orginZoomScale, animated: true)
        scrollView.setContentOffset(orginOffset, animated: true)
    }
    
    @objc private func didReset() {
        reset()
    }
    
    @objc private func didCancel() {
        self.cancel?()
    }
    
    @objc private func didConfirm() {
        self.completion?(self.getCropImage())
    }
}

@available(iOSApplicationExtension, unavailable)
extension ImageCropView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.resetButton?.isEnabled = true
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.resetButton?.isEnabled = (scrollView.zoomScale != 1)
        if scrollView.zoomScale < 1 {
            let top = (scrollView.frame.height - imageView.frame.height)/2
            let left = (scrollView.frame.width - imageView.frame.width)/2
            scrollView.contentInset = UIEdgeInsets(top: max(0, top), left: max(0, left), bottom: 0, right: 0)
        } else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
}
