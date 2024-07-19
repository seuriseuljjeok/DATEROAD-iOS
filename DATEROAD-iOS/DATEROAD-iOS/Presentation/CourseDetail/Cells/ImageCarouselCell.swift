//
//  ImageCarouselCell.swift
//  DATEROAD-iOS
//
//  Created by 김민서 on 7/1/24.
//

import UIKit

import SnapKit
import Then

protocol ImageCarouselDelegate: AnyObject {
    func didSwipeImage(index: Int, vc: UIPageViewController, vcData: [UIViewController])
}

final class ImageCarouselCell: BaseCollectionViewCell {
    
    // MARK: - UI Properties
    
    let pageControllView = BottomPageControllView()
    
    // MARK: - Properties
    
    var vcData: [UIViewController] = []
    
    var thumbnailModel: ThumbnailModel?
    
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    
    static let identifier: String = "ImageCarouselCell"
    
    weak var delegate: ImageCarouselDelegate?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        setDelegate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPageVC(thumbnailModel: [ThumbnailModel]) {
        vcData = thumbnailModel.map { thumbnail in
            let vc = UIViewController()
            let imageView = UIImageView()
            if let url = URL(string: thumbnail.imageUrl) {
                imageView.kf.setImage(with: url)
            }
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            vc.view.addSubview(imageView)
            imageView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            return vc
        }
        setVCInPageVC()
    }
    
    override func setHierarchy() {
        self.addSubview(pageViewController.view)
    }
    
    override func setLayout() {
        pageViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func setVCInPageVC() {
        if let firstVC = vcData.first {
            pageViewController.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func setDelegate() {
        pageViewController.delegate = self
        pageViewController.dataSource = self
    }
}


extension ImageCarouselCell: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let currentVC = pageViewController.viewControllers?.first,
              let currentIndex = vcData.firstIndex(of: currentVC) else { return }
        self.delegate?.didSwipeImage(index: currentIndex, vc: pageViewController, vcData: vcData)
    }
}

extension ImageCarouselCell: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = vcData.firstIndex(of: viewController) else { return nil }
        let previousIndex = index - 1
        
        return previousIndex < 0 ? nil : vcData[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = vcData.firstIndex(of: viewController) else { return nil }
        let nextIndex = index + 1
        
        return nextIndex == vcData.count ? nil : vcData[nextIndex]
    }
}
