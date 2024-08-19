//
//  MainViewController.swift
//  DATEROAD-iOS
//
//  Created by 윤희슬 on 7/10/24.
//

import UIKit

final class MainViewController: BaseViewController {
    
    // MARK: - UI Properties
    
    private var mainView: MainView
    
    private let loadingView: DRLoadingView = DRLoadingView()
    
    private let errorView: DRErrorViewController = DRErrorViewController()
    
    
    // MARK: - Properties
    
    private var mainViewModel: MainViewModel
    
    private lazy var userName = mainViewModel.mainUserData.value?.name
    
    private lazy var point = mainViewModel.mainUserData.value?.point
    
    
    // MARK: - Life Cycles
    
    init(viewModel: MainViewModel) {
        self.mainViewModel = viewModel
        self.mainView = MainView(mainSectionData: self.mainViewModel.sectionData)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCell()
        setDelegate()
        setAddTarget()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        self.mainViewModel.fetchSectionData()
    }
    
    override func setHierarchy() {
        self.view.addSubviews(loadingView, mainView)
    }
    
    override func setLayout() {
        loadingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        mainView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().inset(view.frame.height * 0.1)
        }
    }
    
    override func setStyle() {
        self.navigationController?.navigationBar.isHidden = true
    }
}

extension MainViewController {
    
    func bindViewModel() {
        self.mainViewModel.onFailNetwork.bind { [weak self] onFailure in
            guard let onFailure else { return }
            if onFailure {
                let errorVC = DRErrorViewController()
                self?.navigationController?.pushViewController(errorVC, animated: false)
            }
        }
        
        self.mainViewModel.onLoading.bind { [weak self] onLoading in
            guard let onLoading, let onFailNetwork = self?.mainViewModel.onFailNetwork.value else { return }
            if !onFailNetwork {
                self?.loadingView.isHidden = !onLoading
                self?.mainView.isHidden = onLoading
                self?.tabBarController?.tabBar.isHidden = onLoading
            }
        }
        
        self.mainViewModel.onReissueSuccess.bind { [weak self] onSuccess in
            guard let onSuccess else { return }
            if onSuccess {
                // TODO: - 서버 통신 재시도
            } else {
                self?.navigationController?.pushViewController(SplashViewController(splashViewModel: SplashViewModel()), animated: false)
            }
        }
        
        self.mainViewModel.isSuccessGetUserInfo.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            if isSuccess {
                self?.mainView.mainCollectionView.reloadData()
            }
        }
        
        self.mainViewModel.isSuccessGetHotDate.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            if isSuccess {
                self?.mainView.mainCollectionView.reloadData()
            }
        }
        
        self.mainViewModel.isSuccessGetBanner.bind { [weak self] isSuccess in
            guard let isSuccess,
                  let cell = self?.mainView.mainCollectionView.cellForItem(at: IndexPath(item: 0, section: 2)) as? BannerCell
            else { return }
            if isSuccess {
                self?.mainView.mainCollectionView.reloadData()
            }
        }
        
        self.mainViewModel.isSuccessGetNewDate.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            if isSuccess {
                self?.mainView.mainCollectionView.reloadData()
            }
        }
        
        self.mainViewModel.isSuccessGetUpcomingDate.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            if isSuccess {
                self?.mainView.mainCollectionView.reloadData()
            }
        }
        
        self.mainViewModel.currentIndex.bind { [weak self] index in
            guard let index else { return }
            let count = 5
            print("index \(index.row + 1)")
            self?.updateBannerCell(index: index.row, count: count)
        }
    }
    
    func registerCell() {
        self.mainView.mainCollectionView.register(UpcomingDateCell.self, forCellWithReuseIdentifier: UpcomingDateCell.cellIdentifier)
        self.mainView.mainCollectionView.register(HotDateCourseCell.self, forCellWithReuseIdentifier: HotDateCourseCell.cellIdentifier)
        self.mainView.mainCollectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.cellIdentifier)
        self.mainView.mainCollectionView.register(NewDateCourseCell.self, forCellWithReuseIdentifier: NewDateCourseCell.cellIdentifier)
        self.mainView.mainCollectionView.register(MainHeaderView.self, forSupplementaryViewOfKind: MainHeaderView.elementKinds, withReuseIdentifier: MainHeaderView.identifier)
        self.mainView.mainCollectionView.register(BannerIndexFooterView.self, forSupplementaryViewOfKind: BannerIndexFooterView.elementKinds, withReuseIdentifier: BannerIndexFooterView.identifier)

    }
    
    func setDelegate() {
        self.mainView.mainCollectionView.dataSource = self
        self.mainView.mainCollectionView.delegate = self
        self.mainView.delegate = self
    }
    
    func setAddTarget() {
        self.mainView.floatingButton.addTarget(self, action: #selector(pushToAddCourseVC), for: .touchUpInside)
    }
    
    func updateBannerCell(index: Int, count: Int) {
        guard let bannerIndexView = self.mainView.mainCollectionView.supplementaryView(forElementKind: BannerIndexFooterView.elementKinds, at: IndexPath(item: 0, section: 2)) as? BannerIndexFooterView
        else { return }
        bannerIndexView.bindIndexData(currentIndex: index, count: count)
    }
    
    @objc
    func dismissView() {
        let addCourseVC = AddCourseFirstViewController(viewModel: AddCourseViewModel())
        self.navigationController?.pushViewController(addCourseVC, animated: false)
    }
    
    @objc
    func pushToAddCourseVC() {
        let addCourseVC = AddCourseFirstViewController(viewModel: AddCourseViewModel())
        self.navigationController?.pushViewController(addCourseVC, animated: false)
    }
    
    // 코스 둘러보기 뷰컨으로 이동
    @objc
    func pushToCourseVC() {
        self.tabBarController?.selectedIndex = 1
    }
    
    @objc
    func pushToDateDetailVC(_ sender: UIButton) {
        let dateID = sender.tag
        print("Button with DateID \(dateID) pressed")
        let upcomingDateDetailVC = UpcomingDateDetailViewController()
        upcomingDateDetailVC.upcomingDateDetailViewModel = DateDetailViewModel(dateID: dateID)
        upcomingDateDetailVC.setColor(index: dateID)
        self.navigationController?.pushViewController(upcomingDateDetailVC, animated: true)
    }
    
    @objc
    func pushToDateScheduleVC() {
        print("pushToDateScheduleVC")
        self.tabBarController?.selectedIndex = 2
    }
    
    @objc
    func pushToPointDetailVC() {
        guard let userName = self.userName, let totalPoint = self.point else {
            print("User name or point is nil")
            return
        }
        let pointDetailVC = PointDetailViewController(pointViewModel: PointViewModel(userName: userName, totalPoint: totalPoint))
        self.navigationController?.pushViewController(pointDetailVC, animated: false)
    }
}

extension MainViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        
        if contentOffsetY < 0 {
            // 맨 위에서 아래로 당겼을 때
            mainView.mainCollectionView.backgroundColor = UIColor(resource: .deepPurple)
        } else {
            // 일반적인 스크롤 상태
            mainView.mainCollectionView.backgroundColor = UIColor(resource: .drWhite)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1 {
            // 마지막 셀의 렌더링이 완료되었다면
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 약간의 지연을 준 후 로딩 상태 업데이트
                self.mainViewModel.setLoading()
            }
        }
    }
    
}

extension MainViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.mainViewModel.sectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.mainViewModel.sectionData[section] {
        case .upcomingDate:
            return 1
        case .hotDateCourse:
            return self.mainViewModel.hotCourseData.value?.count ?? 0
        case .banner:
            return self.mainViewModel.bannerData.value?.count ?? 0
        case .newDateCourse:
            return self.mainViewModel.newCourseData.value?.count ?? 0
        }

    }
    
    // TODO: - 다가오는 일정 없는 경우 로직 수정
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch self.mainViewModel.sectionData[indexPath.section] {
        case .upcomingDate:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UpcomingDateCell.cellIdentifier, for: indexPath) as? UpcomingDateCell else { return UICollectionViewCell() }
            cell.bindData(upcomingData: mainViewModel.upcomingData.value, mainUserData: mainViewModel.mainUserData.value)
            // Set button actions
            let pointLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(pushToPointDetailVC))
            cell.pointLabel.addGestureRecognizer(pointLabelTapGesture)
            cell.dateTicketView.moveButton.tag = mainViewModel.upcomingData.value?.dateId ?? 0
            cell.dateTicketView.moveButton.addTarget(self, action: #selector(pushToDateDetailVC(_:)), for: .touchUpInside)
            cell.emptyTicketView.moveButton.addTarget(self, action: #selector(pushToDateScheduleVC), for: .touchUpInside)
            
            // Debug prints
            print("UpcomingDateCell configured")
            print("DateTicketView Button Tag: \(cell.dateTicketView.moveButton.tag)")
            return cell
            
        case .hotDateCourse:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotDateCourseCell.cellIdentifier, for: indexPath) as? HotDateCourseCell else { return UICollectionViewCell() }
            cell.bindData(hotDateData: mainViewModel.hotCourseData.value?[indexPath.row])
            return cell
            
        case .banner:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.cellIdentifier, for: indexPath) as? BannerCell else { return UICollectionViewCell() }
            cell.bindData(bannerData: mainViewModel.bannerData.value?[indexPath.row])
            return cell
            
        case .newDateCourse:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewDateCourseCell.cellIdentifier, for: indexPath) as? NewDateCourseCell else { return UICollectionViewCell() }
            cell.bindData(newDateData: mainViewModel.newCourseData.value?[indexPath.row])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == StringLiterals.Common.header {
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MainHeaderView.identifier, for: indexPath)
                    as? MainHeaderView else { return UICollectionReusableView() }
            
            switch mainViewModel.sectionData[indexPath.section] {
            case .upcomingDate, .banner:
                return header
                
            case .hotDateCourse:
                header.viewMoreButton.addTarget(self, action: #selector(pushToCourseVC), for: .touchUpInside)
                header.bindTitle(section: .hotDateCourse, nickname: mainViewModel.nickname.value)
                
            case .newDateCourse:
                header.viewMoreButton.addTarget(self, action: #selector(pushToCourseVC), for: .touchUpInside)
                header.bindTitle(section: .newDateCourse, nickname: nil)
            }
            return header
        } else {
            guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BannerIndexFooterView.identifier, for: indexPath)
                    as? BannerIndexFooterView else { return UICollectionReusableView() }
            let index = mainViewModel.currentIndex.value?.row ?? 0
            footer.bindIndexData(currentIndex: index, count: 5)
            return footer
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch self.mainViewModel.sectionData[indexPath.section] {
        case .hotDateCourse:
            let courseId = mainViewModel.hotCourseData.value?[indexPath.item].courseId ?? 0
            self.navigationController?.pushViewController(CourseDetailViewController(viewModel: CourseDetailViewModel(courseId: courseId)), animated: true)
            
        case .newDateCourse:
            let courseId = mainViewModel.newCourseData.value?[indexPath.item].courseId ?? 0
            self.navigationController?.pushViewController(CourseDetailViewController(viewModel: CourseDetailViewModel(courseId: courseId)), animated: true)
            
        case .banner:
            let id = mainViewModel.bannerData.value?[indexPath.item].advertisementId ?? 1
            let bannerDtailVC = BannerDetailViewController(viewModel: CourseDetailViewModel(courseId: 7), advertismentId: id)
            self.navigationController?.pushViewController(bannerDtailVC, animated: false)
        default:
            print("default")
        }
    }
    
}

extension MainViewController: BannerIndexDelegate {
    func bindIndex(currentIndex: Int) {
        self.mainViewModel.currentIndex.value?.row = currentIndex
    }
}
