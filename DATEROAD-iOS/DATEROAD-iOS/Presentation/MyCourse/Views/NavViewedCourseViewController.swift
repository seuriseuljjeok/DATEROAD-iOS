//
//  NavViewedCourseViewController.swift
//  DATEROAD-iOS
//
//  Created by 이수민 on 7/7/24.
//

import UIKit

import SnapKit
import Then

final class NavViewedCourseViewController: BaseNavBarViewController {

    // MARK: - UI Properties
    
    private var navViewedCourseView = MyCourseListView()
        
    private let errorView: DRErrorViewController = DRErrorViewController()
    
    // MARK: - Properties
    
    private var viewedCourseViewModel: MyCourseListViewModel
    
    // MARK: - LifeCycle
    
    init(viewedCourseViewModel: MyCourseListViewModel) {
        self.viewedCourseViewModel = viewedCourseViewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.viewedCourseViewModel.setNavViewedCourseLoading()
        self.viewedCourseViewModel.setNavViewedCourseData()
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLeftBackButton()
        setTitleLabelStyle(title: StringLiterals.ViewedCourse.title, alignment: .center)
        register()
        setDelegate()
        bindViewModel()
        setEmptyView()
    }
    
    override func setHierarchy() {
        super.setHierarchy()
        
        self.contentView.addSubviews(navViewedCourseView)
    }
    
    override func setLayout() {
        super.setLayout()

        navViewedCourseView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func setStyle() {
        super.setStyle()
        
        self.view.backgroundColor = UIColor(resource: .drWhite)
    }

}

// MARK: - EmptyView Methods

extension NavViewedCourseViewController {
    private func setEmptyView() {
        var isEmpty = (viewedCourseViewModel.viewedCourseData.value?.count == 0)
        navViewedCourseView.emptyView.isHidden = !isEmpty
        if isEmpty {
            navViewedCourseView.emptyView.do {
                $0.setEmptyView(emptyImage: UIImage(resource: .emptyPastSchedule),
                                emptyTitle: StringLiterals.EmptyView.emptyNavViewedCourse)
            }
        }
    }
}

// MARK: - DataBind

extension NavViewedCourseViewController {
    func bindViewModel() {
        self.viewedCourseViewModel.onReissueSuccess.bind { [weak self] onSuccess in
            guard let onSuccess else { return }
            if onSuccess {
                // TODO: - 서버 통신 재시도
            } else {
                self?.navigationController?.pushViewController(SplashViewController(splashViewModel: SplashViewModel()), animated: false)
            }
        }
        
        self.viewedCourseViewModel.onNavViewedCourseFailNetwork.bind { [weak self] onFailure in
            guard let onFailure else { return }
            if onFailure {
                self?.hideLoadingView()
                let errorVC = DRErrorViewController()
                self?.navigationController?.pushViewController(errorVC, animated: false)
            }
        }

        self.viewedCourseViewModel.onNavViewedCourseLoading.bind { [weak self] onLoading in
            guard let onLoading, let onFailNetwork = self?.viewedCourseViewModel.onViewedCourseFailNetwork.value else { return }
            if !onFailNetwork {
                onLoading ? self?.showLoadingView() : self?.hideLoadingView()
                self?.navViewedCourseView.isHidden = onLoading
            }
        }
        
        self.viewedCourseViewModel.isSuccessGetNavViewedCourseInfo.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            if isSuccess {
                self?.setEmptyView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    self?.viewedCourseViewModel.setNavViewedCourseLoading()
                }
            }
        }
    }
}


// MARK: - CollectionView Methods

extension NavViewedCourseViewController {
    private func register() {
        navViewedCourseView.myCourseListCollectionView.register(MyCourseListCollectionViewCell.self, forCellWithReuseIdentifier: MyCourseListCollectionViewCell.cellIdentifier)
    }
    
    private func setDelegate() {
        navViewedCourseView.myCourseListCollectionView.delegate = self
        navViewedCourseView.myCourseListCollectionView.dataSource = self
    }
}

// MARK: - Delegate

extension NavViewedCourseViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: ScreenUtils.width, height: 140)
    }
}

// MARK: - DataSource

extension NavViewedCourseViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewedCourseViewModel.viewedCourseData.value?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCourseListCollectionViewCell.cellIdentifier, for: indexPath) as? MyCourseListCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.dataBind(viewedCourseViewModel.viewedCourseData.value?[indexPath.item], indexPath.item)
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushToCourseDetailVC(_:))))
        return cell
    }
    
    @objc func pushToCourseDetailVC(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: navViewedCourseView.myCourseListCollectionView)
        let indexPath = navViewedCourseView.myCourseListCollectionView.indexPathForItem(at: location)
       
       if let index = indexPath {
          guard let courseId = viewedCourseViewModel.viewedCourseData.value?[indexPath?.item ?? 0].courseId else {return}
          
          let courseDetailViewModel = CourseDetailViewModel(courseId: courseId)
          let addScheduleViewModel = AddScheduleViewModel()
          addScheduleViewModel.viewedDateCourseByMeData = courseDetailViewModel
          addScheduleViewModel.isImporting = true
          
          let vc = AddScheduleFirstViewController(viewModel: addScheduleViewModel)
          self.navigationController?.pushViewController(vc, animated: false)
          
          // 데이터를 바인딩합니다.
          vc.pastDateBindViewModel()
       }
    }
    
}
