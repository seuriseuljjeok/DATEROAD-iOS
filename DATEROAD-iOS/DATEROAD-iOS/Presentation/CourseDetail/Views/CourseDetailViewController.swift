//
//  CourseDetailViewController.swift
//  DATEROAD-iOS
//
//  Created by 김민서 on 7/12/24.
//

import UIKit

import SnapKit
import Then

final class CourseDetailViewController: BaseViewController {
    
    // MARK: - UI Properties
    
    private let errorView: DRErrorViewController = DRErrorViewController()
    
    private let courseDetailView: CourseDetailView
    
    private let courseInfoTabBarView = CourseDetailBottomTabBarView()
    
    private var deleteCourseSettingView = DeleteCourseSettingView()
    
    // MARK: - Properties
    
    private let courseDetailViewModel: CourseDetailViewModel
    
    private let collectionViewUtils = CollectionViewUtils()
    
    private var currentPage: Int = 0
    
    var courseId: Int?
    
    var isFirstLike: Bool = true
    
    var localLikeNum: Int = 0
    
    private var isLikeNetwork: Bool = false
    
    init(viewModel: CourseDetailViewModel) {
        self.courseDetailViewModel = viewModel
        self.courseId = self.courseDetailViewModel.courseId
        self.courseDetailView = CourseDetailView(courseDetailSection:self.courseDetailViewModel.sections)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        setDelegate()
        registerCell()
        setAddTarget()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.courseDetailViewModel.getCourseDetail()
    }
    
    override func setHierarchy() {
        super.setHierarchy()
        
        self.view.addSubviews(courseDetailView, courseInfoTabBarView)
    }
    
    override func setLayout() {
        super.setLayout()
        
        self.tabBarController?.tabBar.isHidden = true
        courseInfoTabBarView.isHidden = true
        
        courseDetailView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        courseInfoTabBarView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(108)
        }
    }
    
    func setDelegate() {
        courseDetailView.mainCollectionView.delegate = self
        courseDetailView.mainCollectionView.dataSource = self
        courseDetailView.stickyHeaderNavBarView.delegate = self
    }
    
    func registerCell() {
        courseDetailView.mainCollectionView.do {
            $0.register(ImageCarouselCell.self, forCellWithReuseIdentifier: ImageCarouselCell.cellIdentifier)
            
            $0.register(TitleInfoCell.self, forCellWithReuseIdentifier: TitleInfoCell.cellIdentifier)
            
            $0.register(MainContentsCell.self, forCellWithReuseIdentifier: MainContentsCell.cellIdentifier)
            
            $0.register(TimelineInfoCell.self, forCellWithReuseIdentifier: TimelineInfoCell.cellIdentifier)
            
            $0.register(CoastInfoCell.self, forCellWithReuseIdentifier: CoastInfoCell.cellIdentifier)
            
            $0.register(TagInfoCell.self, forCellWithReuseIdentifier: TagInfoCell.cellIdentifier)
            
            $0.register(VisitDateView.self, forSupplementaryViewOfKind: VisitDateView.elementKinds, withReuseIdentifier: VisitDateView.identifier)
            
            $0.register(GradientView.self, forSupplementaryViewOfKind: GradientView.elementKinds, withReuseIdentifier: GradientView.identifier)
            
            $0.register(InfoBarView.self, forSupplementaryViewOfKind: InfoBarView.elementKinds, withReuseIdentifier: InfoBarView.identifier)
            
            $0.register(InfoHeaderView.self, forSupplementaryViewOfKind: InfoHeaderView.elementKinds, withReuseIdentifier: InfoHeaderView.identifier)
            
            $0.register(TimelineHeaderView.self, forSupplementaryViewOfKind: TimelineHeaderView.elementKinds, withReuseIdentifier: TimelineHeaderView.identifier)
            
            $0.register(BottomPageControllView.self, forSupplementaryViewOfKind: BottomPageControllView.elementKinds, withReuseIdentifier: BottomPageControllView.identifier)
            
            $0.register(ContentMaskView.self, forSupplementaryViewOfKind: ContentMaskView.elementKinds, withReuseIdentifier: ContentMaskView.identifier)
        }
    }
    
    func bindViewModel() {
        
        self.courseDetailViewModel.onFailNetwork.bind { [weak self] onFailure in
            guard let onFailure else { return }
            if onFailure {
                let errorVC = DRErrorViewController()
                self?.navigationController?.pushViewController(errorVC, animated: false)
            }
        }
        
        self.courseDetailViewModel.onLoading.bind { [weak self] onLoading in
            guard let onLoading, let onFailNetwork = self?.courseDetailViewModel.onFailNetwork.value else { return }
            if !onFailNetwork {
                onLoading ? self?.showLoadingView() : self?.hideLoadingView()
                self?.courseDetailView.isHidden = onLoading
            }
        }
        
        self.courseDetailViewModel.onReissueSuccess.bind { [weak self] onSuccess in
            guard let onSuccess else { return }
            if onSuccess {
                // TODO: - 서버 통신 재시도
            } else {
                self?.navigationController?.pushViewController(SplashViewController(splashViewModel: SplashViewModel()), animated: false)
            }
        }
        
        courseDetailViewModel.currentPage.bind { [weak self] currentPage in
            guard let self = self else { return }
            if let bottomPageControllView = self.courseDetailView.mainCollectionView.supplementaryView(forElementKind: BottomPageControllView.elementKinds, at: IndexPath(item: 0, section: 0)) as? BottomPageControllView {
                bottomPageControllView.pageIndex = currentPage ?? 0
            }
        }
        
        courseDetailViewModel.isSuccessGetData.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            self?.courseDetailViewModel.setLoading()
            
            if isSuccess {
                self?.localLikeNum = self?.courseDetailViewModel.likeSum.value ?? 0
                self?.setSetctionCount()
                self?.setTabBarVisibility()
                self?.setNavBarVisibility()
                self?.courseDetailView.mainCollectionView.reloadData()
            }
        }
        
        courseDetailViewModel.isAccess.bind { [weak self] isAccess in
            guard let isAccess else { return }
            self?.courseDetailView.isAccess = isAccess
            self?.courseDetailView.mainCollectionView.reloadData()
        }
        
        courseDetailViewModel.isUserLiked.bind { [weak self] isUserLiked in
            guard let self = self else { return }
            self.updateLikeButtonColor(isLiked: isUserLiked ?? false)
        }
        
    }
    
    func setAddTarget() {
        deleteCourseSettingView.deleteLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBottomSheetLabel(sender:))))
        courseInfoTabBarView.likeButtonView.isUserInteractionEnabled = true
        courseInfoTabBarView.likeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapLikeButton)))
        courseInfoTabBarView.bringCourseButton.addTarget(self, action: #selector(didTapMySchedule), for: .touchUpInside)
    }
    
}

extension CourseDetailViewController: DRCustomAlertDelegate {
    
    func action(rightButtonAction: RightButtonType) {
        switch rightButtonAction {
        case .addCourse:
            didTapAddCourseButton()
        case .checkCourse:
            handleCourseAccess()
        case .declareCourse:
            present(DRWebViewController(urlString: "https://tally.so/r/w4L1a5"), animated: true)
        case .deleteCourse:
            deleteCourse()
        default:
            return
        }
        setSetctionCount()
        setTabBarVisibility()
    }
    
    private func handleCourseAccess() {
        let courseId = self.courseDetailViewModel.courseId
        
        if courseDetailViewModel.haveFreeCount.value == true {
            //무료 열람 기회 사용
            let request = PostUsePointRequest(point: 50, type: "POINT_USED", description: "무료 열람 기회 사용")
            self.courseDetailViewModel.postUsePoint(courseId: courseId, request: request)
            self.courseDetailViewModel.isAccess.value = true
            dismiss(animated: false)
        } else {
            if courseDetailViewModel.havePoint.value == true {
                //포인트로 구입
                let request = PostUsePointRequest(point: 50, type: "POINT_USED", description: StringLiterals.CourseDetail.viewCourse)
                self.courseDetailViewModel.postUsePoint(courseId: courseId, request: request)
                self.courseDetailViewModel.isAccess.value = true
                dismiss(animated: false)
            } else {
                showPointAlert()
            }
        }
        setNavBarVisibility()
        setSetctionCount()
        setTabBarVisibility()
    }
    
    private func deleteCourse() {
        self.dismiss(animated: true)
        courseDetailViewModel.deleteCourse { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("성공적으로 삭제")
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    print("삭제 실패 ㅠ")
                }
            }
        }
        courseDetailView.mainCollectionView.reloadData()
    }
}

extension CourseDetailViewController: ContentMaskViewDelegate {
    
    //버튼 분기 처리하기
    func didTapViewButton() {
        courseDetailViewModel.haveFreeCount.value == true ? showFreeViewAlert() : showReadCourseAlert()
    }
    
    // 무료 사용 기회를 다 쓴 경우의 알림
    func showReadCourseAlert() {
        presentCustomAlert(
            title: StringLiterals.Alert.buyCourse,
            description: StringLiterals.Alert.canNotRefund,
            action: .checkCourse,
            buttonText: StringLiterals.CourseDetail.check
        )
    }
    
    // 무료 사용 기회가 남은 경우의 알림
    func showFreeViewAlert() {
        presentCustomAlert(
            title: StringLiterals.CourseDetail.freeViewTitle,
            description: StringLiterals.CourseDetail.freeViewDescription,
            action: .checkCourse,
            buttonText: StringLiterals.CourseDetail.check
        )
    }
    
    //포인트가 부족할 때
    func showPointAlert(){
        presentCustomAlert(
            title: StringLiterals.CourseDetail.insufficientPointsTitle,
            description: StringLiterals.CourseDetail.insufficientPointsDescription,
            action: .addCourse,
            buttonText: StringLiterals.CourseDetail.addCourse
        )
    }
    
    // 신고 혹은 삭제 버튼 클릭 시 처리
    @objc func didTapBottomSheetLabel(sender: UITapGestureRecognizer) {
        print("삭제하기 클릭")
        self.dismiss(animated: true)
        courseDetailViewModel.isCourseMine.value == true ? showDeleteAlert() : showDeclareAlert()
        
    }
    
    //바텀 시트에서 신고하기 클릭시 팝업창
    func showDeclareAlert(){
        presentCustomAlert(
            title: StringLiterals.CourseDetail.declareTitle,
            description: StringLiterals.CourseDetail.declareDescription,
            action: .declareCourse
        )
    }
    
    //바텀 시트에서 삭제하기 클릭시 팝업창
    func showDeleteAlert(){
        presentCustomAlert(
            title: StringLiterals.CourseDetail.deleteTitle,
            description: StringLiterals.CourseDetail.deleteDescription,
            action: .deleteCourse
        )
    }
    
    func presentCustomAlert(title: String, description: String, action: RightButtonType, buttonText: String = "확인") {
        let alertVC = DRCustomAlertViewController(
            rightActionType: action,
            alertTextType: .hasDecription,
            alertButtonType: .twoButton,
            titleText: title,
            descriptionText: description,
            rightButtonText: buttonText
        )
        alertVC.delegate = self
        alertVC.modalPresentationStyle = .overFullScreen
        present(alertVC, animated: false)
    }
    
    
    //코스 등록하기로 화면 전환
    func didTapAddCourseButton() {
        let addCourseVC = AddCourseFirstViewController(viewModel: AddCourseViewModel())
        self.navigationController?.pushViewController(addCourseVC, animated: false)
    }
    
}

extension CourseDetailViewController: StickyHeaderNavBarViewDelegate, DRBottomSheetDelegate {
    
    func didTapBackButton() {
        navigationController?.popViewController(animated: false)
        AmplitudeManager.shared.trackEventWithProperties(StringLiterals.Amplitude.EventName.clickCourseBack, properties: [StringLiterals.Amplitude.Property.purchaseSuccess : courseDetailViewModel.purchaseSuccess])
    }
    
    func didTapMoreButton() {
        let bottomSheetVC = DRBottomSheetViewController(
            contentView: deleteCourseSettingView,
            height: 210,
            buttonType: DisabledButton(),
            buttonTitle: StringLiterals.Common.close
        )
        bottomSheetVC.delegate = self
        deleteCourseSettingView.deleteLabel.text = courseDetailViewModel.isCourseMine.value == true ? StringLiterals.CourseDetail.deleteCourse : StringLiterals.CourseDetail.delclareCourse
        bottomSheetVC.modalPresentationStyle = .overFullScreen
        present(bottomSheetVC, animated: true)
    }
    
    func didTapBottomButton() {
        self.dismiss(animated: true)
    }
}


extension CourseDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 350 {
            courseDetailView.stickyHeaderNavBarView.backgroundColor = .white
            courseDetailView.stickyHeaderNavBarView.moreButton.tintColor = .gray600
            courseDetailView.stickyHeaderNavBarView.previousButton.tintColor = .gray600
        } else {
            courseDetailView.stickyHeaderNavBarView.backgroundColor = .clear
            courseDetailView.stickyHeaderNavBarView.moreButton.tintColor = .drWhite
            courseDetailView.stickyHeaderNavBarView.previousButton.tintColor = .drWhite
        }
    }
}

private extension CourseDetailViewController {
    
    @objc
    func didTapMySchedule() {
        let courseId = courseDetailViewModel.courseId
        let courseDetailViewModel = CourseDetailViewModel(courseId: courseId)
        let addScheduleViewModel = AddScheduleViewModel()
        
        addScheduleViewModel.viewedDateCourseByMeData = courseDetailViewModel
        addScheduleViewModel.isImporting = true
        
        let vc = AddScheduleFirstViewController(viewModel: addScheduleViewModel)
       // 데이터를 바인딩합니다.
       vc.pastDateBindViewModel()
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @objc
    func didTapLikeButton() {
        isFirstLike = false
        guard let isLiked = courseDetailViewModel.isUserLiked.value else { return }
        courseDetailViewModel.isUserLiked.value?.toggle()
        
        let likeAction = isLiked ? courseDetailViewModel.deleteLikeCourse : courseDetailViewModel.likeCourse
        likeAction(courseId ?? 0)
        
        self.courseDetailView.mainCollectionView.reloadData()
    }
    
    func updateLikeButtonColor(isLiked: Bool) {
        courseInfoTabBarView.likeButtonImageView.tintColor = isLiked ? UIColor(resource: .deepPurple) : UIColor(resource: .gray200)
    }
    
    func setSetctionCount() {
        courseDetailViewModel.setNumberOfSections(courseDetailViewModel.isAccess.value == true ? 6 : 3)
        courseDetailView.mainCollectionView.reloadData()
    }
    
    func setNavBarVisibility() {
        courseDetailView.stickyHeaderNavBarView.moreButton.isHidden = !(courseDetailViewModel.isAccess.value ?? false)
    }
    
    func setTabBarVisibility() {
        courseInfoTabBarView.isHidden = !(courseDetailViewModel.isAccess.value ?? false) || (courseDetailViewModel.isCourseMine.value == true)
    }
    
}

extension CourseDetailViewController: ImageCarouselDelegate {
    
    func didSwipeImage(index: Int, vc: UIPageViewController, vcData: [UIViewController]) {
        courseDetailViewModel.didSwipeImage(to: index)
    }
    
}

// MARK: - Compositonal Layout

extension CourseDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return courseDetailViewModel.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courseDetailViewModel.numberOfItemsInSection(section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = courseDetailViewModel.fetchSection(at: indexPath.section)
        let isAccess = courseDetailViewModel.isAccess.value ?? false
        
        switch sectionType {
        case .imageCarousel:
            return configureImageCarouselCell(collectionView, indexPath: indexPath, isAccess: isAccess)
        case .titleInfo:
            return configureTitleInfoCell(collectionView, indexPath: indexPath)
        case .mainContents:
            return configureMainContentsCell(collectionView, indexPath: indexPath, isAccess: isAccess)
        case .timelineInfo:
            return configureTimelineInfoCell(collectionView, indexPath: indexPath)
        case .coastInfo:
            return configureCoastInfoCell(collectionView, indexPath: indexPath)
        case .tagInfo:
            return configureTagInfoCell(collectionView, indexPath: indexPath)
        }
    }

    private func configureImageCarouselCell(_ collectionView: UICollectionView, indexPath: IndexPath, isAccess: Bool) -> UICollectionViewCell {
        return collectionViewUtils.dequeueAndConfigureCell(collectionView: collectionView, indexPath: indexPath, identifier: ImageCarouselCell.cellIdentifier) { (cell: ImageCarouselCell) in
            let imageData = courseDetailViewModel.imageData.value ?? []
            cell.setPageVC(thumbnailModel: imageData)
            cell.setAccess(isAccess: isAccess)
            cell.delegate = self
        }
    }

    
    private func configureTitleInfoCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionViewUtils.dequeueAndConfigureCell(collectionView: collectionView, indexPath: indexPath, identifier: TitleInfoCell.cellIdentifier) { (cell: TitleInfoCell) in
            let titleData = courseDetailViewModel.titleHeaderData.value ?? TitleHeaderModel(date: "", title: "", cost: 0, totalTime: 0, city: "")
            cell.setCell(titleHeaderData: titleData)
        }
    }
    
    private func configureMainContentsCell(_ collectionView: UICollectionView, indexPath: IndexPath, isAccess: Bool) -> UICollectionViewCell {
        return collectionViewUtils.dequeueAndConfigureCell(collectionView: collectionView, indexPath: indexPath, identifier: MainContentsCell.cellIdentifier) { (cell: MainContentsCell) in
            let mainData = courseDetailViewModel.mainContentsData.value ?? MainContentsModel(description: "")
            cell.setCell(mainContentsData: mainData)
            cell.mainTextLabel.numberOfLines = isAccess ? 0 : 3
        }
    }
    
    private func configureTimelineInfoCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionViewUtils.dequeueAndConfigureCell(collectionView: collectionView, indexPath: indexPath, identifier: TimelineInfoCell.cellIdentifier) { (cell: TimelineInfoCell) in
            let timelineItem = courseDetailViewModel.timelineData.value?[indexPath.row] ?? TimelineModel(sequence: 0, title: "", duration: 0)
            cell.setCell(timelineData: timelineItem)
        }
    }
    
    private func configureCoastInfoCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionViewUtils.dequeueAndConfigureCell(collectionView: collectionView, indexPath: indexPath, identifier: CoastInfoCell.cellIdentifier) { (cell: CoastInfoCell) in
            let coastData = courseDetailViewModel.titleHeaderData.value?.cost ?? 0
            cell.setCell(coastData: coastData)
        }
    }
    
    private func configureTagInfoCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionViewUtils.dequeueAndConfigureCell(collectionView: collectionView, indexPath: indexPath, identifier: TagInfoCell.cellIdentifier) { (cell: TagInfoCell) in
            let tagData = courseDetailViewModel.tagData.value?[indexPath.row] ?? TagModel(tag: "")
            cell.setCell(tag: tagData.tag)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let isAccess = courseDetailViewModel.isAccess.value ?? false
        let titleHeaderData = courseDetailViewModel.titleHeaderData.value ?? TitleHeaderModel(date: "", title: "", cost: 0, totalTime: 0, city: "")
        let imageData = courseDetailViewModel.imageData.value ?? []
        
        switch kind {
        case VisitDateView.elementKinds:
            return configureVisitDateView(collectionView, indexPath: indexPath, titleHeaderData: titleHeaderData)
        case InfoBarView.elementKinds:
            return configureInfoBarView(collectionView, indexPath: indexPath, titleHeaderData: titleHeaderData)
        case GradientView.elementKinds:
            return configureGradientView(collectionView, indexPath: indexPath)
        case BottomPageControllView.elementKinds:
            return configureBottomPageControlView(collectionView, indexPath: indexPath, imageData: imageData, isAccess: isAccess)
        case ContentMaskView.elementKinds:
            return configureContentMaskView(collectionView, indexPath: indexPath, isAccess: isAccess)
        case InfoHeaderView.elementKinds:
            return configureInfoHeaderView(collectionView, indexPath: indexPath)
        case TimelineHeaderView.elementKinds:
            return configureTimelineHeaderView(collectionView, indexPath: indexPath)
        default:
            return UICollectionReusableView()
        }
    }

    private func configureGradientView(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionReusableView {
        return collectionViewUtils.dequeueAndConfigureSupplementaryView(collectionView: collectionView, indexPath: indexPath, kind: GradientView.elementKinds, identifier: GradientView.identifier) { (view: GradientView) in
        }
    }
    
    private func configureVisitDateView(_ collectionView: UICollectionView, indexPath: IndexPath, titleHeaderData: TitleHeaderModel) -> UICollectionReusableView {
        return collectionViewUtils.dequeueAndConfigureSupplementaryView(collectionView: collectionView, indexPath: indexPath, kind: VisitDateView.elementKinds, identifier: VisitDateView.identifier) { (view: VisitDateView) in
            view.bindDate(titleHeaderData: titleHeaderData)
        }
    }
    
    private func configureInfoBarView(_ collectionView: UICollectionView, indexPath: IndexPath, titleHeaderData: TitleHeaderModel) -> UICollectionReusableView {
        return collectionViewUtils.dequeueAndConfigureSupplementaryView(collectionView: collectionView, indexPath: indexPath, kind: InfoBarView.elementKinds, identifier: InfoBarView.identifier) { (view: InfoBarView) in
            view.bindTitleHeader(titleHeaderData: titleHeaderData)
        }
    }
    
    private func configureBottomPageControlView(_ collectionView: UICollectionView, indexPath: IndexPath, imageData: [ThumbnailModel], isAccess: Bool) -> UICollectionReusableView {
        return collectionViewUtils.dequeueAndConfigureSupplementaryView(collectionView: collectionView, indexPath: indexPath, kind: BottomPageControllView.elementKinds, identifier: BottomPageControllView.identifier) { (view: BottomPageControllView) in
            if !isFirstLike {
                localLikeNum += courseDetailViewModel.isUserLiked.value == true ? 1 : -1
            }
            view.pageIndexSum = imageData.count
            view.bindData(like: localLikeNum)
        }
    }
    
    private func configureContentMaskView(_ collectionView: UICollectionView, indexPath: IndexPath, isAccess: Bool) -> UICollectionReusableView {
        return collectionViewUtils.dequeueAndConfigureSupplementaryView(collectionView: collectionView, indexPath: indexPath, kind: ContentMaskView.elementKinds, identifier: ContentMaskView.identifier) { (view: ContentMaskView) in
            if !isAccess {
                let haveFree = courseDetailViewModel.haveFreeCount.value ?? false
                let count = courseDetailViewModel.conditionalData.value?.free ?? 0
                view.checkFree(haveFree: haveFree, count: count)
                view.delegate = self
            }
        }
    }
    
    private func configureInfoHeaderView(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionReusableView {
        return collectionViewUtils.dequeueAndConfigureSupplementaryView(collectionView: collectionView, indexPath: indexPath, kind: InfoHeaderView.elementKinds, identifier: InfoHeaderView.identifier) { (view: InfoHeaderView) in
            switch courseDetailViewModel.fetchSection(at: indexPath.section) {
            case .coastInfo:
                view.bindTitle(headerTitle: StringLiterals.CourseDetail.coastInfoLabel)
            case .tagInfo:
                view.bindTitle(headerTitle: StringLiterals.CourseDetail.tagInfoLabel)
            default:
                break
            }
        }
    }
    
    private func configureTimelineHeaderView(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionReusableView {
        return collectionViewUtils.dequeueAndConfigureSupplementaryView(collectionView: collectionView, indexPath: indexPath, kind: TimelineHeaderView.elementKinds, identifier: TimelineHeaderView.identifier) { (view: TimelineHeaderView) in
            let startAt = courseDetailViewModel.startAt
            view.bindSubTitle(subTitle: startAt)
        }
    }

}



