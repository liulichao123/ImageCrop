//
//  CustomView.swift
//  test
//
//  Created by 天明 on 2018/7/12.
//  Copyright © 2018年 天明. All rights reserved.
//

import UIKit

struct ImageCropConfig {
    var cropRate: CGFloat = 1
    var edge: CGFloat = 20
    var borderColor: UIColor = UIColor.white
    var borderWidth: CGFloat = 1
    
}

class ImageCropView: UIView {

    private let originalImage: UIImage
    private var config: ImageCropConfig
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var _maskView: UIView!
    private var _rate: CGFloat = 1
    private var _able: Bool
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
        return scrollView
    }

    private func setupViews() {
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
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.layer.masksToBounds = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.backgroundColor = UIColor.black
        scrollView.delegate = self
        
        scrollView.backgroundColor = UIColor.black
        scrollView.layer.borderWidth = config.borderWidth
        scrollView.layer.borderColor = config.borderColor.cgColor
        
        imageView = UIImageView(image: originalImage)
        imageView.frame = CGRect(x: 0, y: 0, width: w, height: h)
        imageView.contentMode = .scaleAspectFill
        scrollView.addSubview(imageView)
        
        var contentSize = scrollView.frame.size
        if originalImage.size.width > originalImage.size.height {
            let _w = originalImage.size.width/originalImage.size.height*h
            if (_w - w) < 0 {
                let _h = w/_rate
                contentSize.height += max(0, _h - h)
            }
            contentSize.width += max(0, _w - w)
        } else {
            let _h = originalImage.size.height/originalImage.size.width*w
            if (_h - h) < 0 {
                let _w = h/_rate
                contentSize.width += max(0, _w - w)
            }
            contentSize.height += max(0, _h - h)
        }
        imageView.frame.size = contentSize
        scrollView.contentSize = contentSize

        imageView.center = CGPoint(x: contentSize.width/2, y: contentSize.height/2)
        scrollView.setContentOffset(CGPoint(x: (contentSize.width-scrollView.frame.width)/2, y: (contentSize.height-scrollView.frame.height)/2), animated: false)
    
        //当图片宽度小于k高度时，让图片宽度占满屏幕
        if _rate < 1 && w != 0 {
            scrollView.zoomScale = self.bounds.width/w
        }
        
        _maskView = UIView(frame: self.bounds)
        _maskView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(_maskView)
        let path = UIBezierPath(rect: self.bounds)
        path.append(UIBezierPath(rect: scrollView.frame).reversing())
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        _maskView.layer.mask = shapeLayer
    }
    
    func getCropImage() -> UIImage? {
        guard _able else { return nil }
        var cropRect = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        
        let scale = max(originalImage.size.width/imageView.frame.width, originalImage.size.height/imageView.frame.height)
        cropRect.origin.x *= scale
        cropRect.origin.y *= scale
        cropRect.size.width *= scale
        cropRect.size.height *= scale
        
        guard let cropCGImage = originalImage.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropCGImage)
    }
}

extension ImageCropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
