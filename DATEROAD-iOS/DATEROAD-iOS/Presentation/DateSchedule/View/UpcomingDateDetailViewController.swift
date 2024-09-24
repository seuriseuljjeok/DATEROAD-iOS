//
//  UpcomingDateDetailViewController.swift
//  DATEROAD-iOS
//
//  Created by 이수민 on 7/8/24.
//

import UIKit

import SnapKit
import Then

final class UpcomingDateDetailViewController: BaseNavBarViewController {

    // MARK: - UI Properties
    
    var upcomingDateDetailContentView = DateDetailContentView()
    
    private let errorView: DRErrorViewController = DRErrorViewController()
    
    
    // MARK: - Properties
    
    var dateID: Int
    
    var upcomingDateDetailViewModel: DateDetailViewModel
    
    private let dateScheduleDeleteView = DateScheduleDeleteView()
    
    
    // MARK: - LifeCycle
    
    init(dateID: Int, upcomingDateDetailViewModel: DateDetailViewModel) {
        self.dateID = dateID
        self.upcomingDateDetailViewModel = upcomingDateDetailViewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLeftBackButton()
        setTitleLabelStyle(title: StringLiterals.DateSchedule.upcomingDate, alignment: .center)
        setRightButtonStyle(image: UIImage(resource: .moreButton))
        setRightButtonAction(target: self, action: #selector(deleteDateCourse))
        bindViewModel()
        setButton()
        registerCell()
        setDelegate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = true
        self.upcomingDateDetailViewModel.setDateDetailLoading()
        self.upcomingDateDetailViewModel.getDateDetailData(dateID: self.dateID)
    }
    
    override func setHierarchy() {
        super.setHierarchy()
        
        contentView.addSubview(upcomingDateDetailContentView)
    }
    
    override func setLayout() {
        super.setLayout()

        upcomingDateDetailContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// MARK: - UI Setting Methods

extension UpcomingDateDetailViewController {
    func bindViewModel() {
        
        self.upcomingDateDetailViewModel.onDateDetailLoading.bind { [weak self] onLoading in
            guard let onLoading, 
                    let onFailNetwork = self?.upcomingDateDetailViewModel.onFailNetwork.value
            else { return }
             if !onFailNetwork {
                 onLoading ? self?.showLoadingView() : self?.hideLoadingView()
                 self?.upcomingDateDetailContentView.isHidden = onLoading
                 self?.topInsetView.isHidden = onLoading
                 self?.navigationBarView.isHidden = onLoading
             }
            if !onFailNetwork {
                if onLoading {
                    self?.showLoadingView()
                    self?.upcomingDateDetailContentView.isHidden = true
                    self?.topInsetView.isHidden = onLoading
                    self?.navigationBarView.isHidden = onLoading
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.upcomingDateDetailContentView.isHidden = false
                        self?.topInsetView.isHidden = onLoading
                        self?.navigationBarView.isHidden = onLoading
                        self?.hideLoadingView()
                    }
                }
            }
         }
        
        self.upcomingDateDetailViewModel.onReissueSuccess.bind { [weak self] onSuccess in
            guard let onSuccess else { return }
            if onSuccess {
                // TODO: - 서버 통신 재시도
            } else {
                self?.navigationController?.pushViewController(SplashViewController(splashViewModel: SplashViewModel()), animated: false)
            }
        }
        
        self.upcomingDateDetailViewModel.onFailNetwork.bind { [weak self] onFailure in
            guard let onFailure else { return }
            if onFailure {
                self?.hideLoadingView()
                let errorVC = DRErrorViewController()
                self?.navigationController?.pushViewController(errorVC, animated: false)
            }
        }
        
        self.upcomingDateDetailViewModel.isSuccessGetDateDetailData.bind { [weak self] isSuccess in
            guard let isSuccess,  let data = self?.upcomingDateDetailViewModel.dateDetailData.value else { return }
            if isSuccess {
                self?.upcomingDateDetailContentView.dataBind(data)
                self?.upcomingDateDetailContentView.dateTimeLineCollectionView.reloadData()
                self?.upcomingDateDetailViewModel.setDateDetailLoading()
            }
        }
        
        self.upcomingDateDetailViewModel.isSuccessDeleteDateScheduleData.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            if isSuccess {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func setButton() {
        upcomingDateDetailContentView.dDayButton.isHidden = false
        upcomingDateDetailContentView.kakaoShareButton.isHidden = false
        upcomingDateDetailContentView.courseShareButton.isHidden = true
        
        upcomingDateDetailContentView.kakaoShareButton.addTarget(self, action: #selector(tapKakaoButton), for: .touchUpInside)
    }
    
    func setColor(index: Int) {
        let colorIndex = index % 3
        if colorIndex == 0 {
            self.setBackgroundColor(color: UIColor(resource: .pink200))
        } else if colorIndex == 1 {
            self.setBackgroundColor(color: UIColor(resource: .purple200))
        } else {
            self.setBackgroundColor(color: UIColor(resource: .lime))
        }
        upcomingDateDetailContentView.setColor(index: index)
    }
    
}

// MARK: - Alert Methods

extension UpcomingDateDetailViewController: DRCustomAlertDelegate {
    @objc
    private func tapKakaoButton() {
        let customAlertVC = DRCustomAlertViewController(rightActionType: RightButtonType.kakaoShare,
                                                      alertTextType: .noDescription,
                                                      alertButtonType: .twoButton,
                                                      titleText: StringLiterals.Alert.kakaoAlert,
                                                      rightButtonText: "열기")
        customAlertVC.delegate = self
        customAlertVC.modalPresentationStyle = .overFullScreen
        self.present(customAlertVC, animated: false)
    }
    
    @objc
    private func tapDeleteLabel() {
        print("dfdsf")
        let customAlertVC = DRCustomAlertViewController(rightActionType: RightButtonType.deleteCourse, alertTextType: .hasDecription, alertButtonType: .twoButton, titleText: StringLiterals.Alert.deleteDateSchedule, descriptionText: StringLiterals.Alert.noMercy, rightButtonText: "삭제")
        customAlertVC.delegate = self
        customAlertVC.modalPresentationStyle = .overFullScreen
        self.present(customAlertVC, animated: false)
    }

    func action(rightButtonAction: RightButtonType) {
           print("all")
           if rightButtonAction == .deleteCourse {
               print("zz")
               upcomingDateDetailViewModel.deleteDateSchdeuleData(dateID: upcomingDateDetailViewModel.dateDetailData.value?.dateID ?? 0)
           } else if rightButtonAction == .kakaoShare {
               upcomingDateDetailViewModel.shareToKakao(context: self)
               print("카카오 공유하기")
           }
       }
}


extension UpcomingDateDetailViewController: DRBottomSheetDelegate {
    @objc
    private func deleteDateCourse() {
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(didTapFirstLabel))
        dateScheduleDeleteView.deleteLabel.addGestureRecognizer(labelTap)
        let bottomSheetVC = DRBottomSheetViewController(contentView: dateScheduleDeleteView, height: 222, buttonType: DisabledButton(), buttonTitle: StringLiterals.DateSchedule.quit)
        bottomSheetVC.modalPresentationStyle = .overFullScreen
        bottomSheetVC.delegate = self
        self.present(bottomSheetVC, animated: false)
    }
    
    func didTapBottomButton() {
        print("hi")
        self.dismiss(animated: false)
    }
    
    @objc
    func didTapFirstLabel() {
        print("sdjflksd ㅇㄴㄹㅁㄴㅇㄹ")
        self.dismiss(animated: false)
        tapDeleteLabel()
    }
    
}


// MARK: - CollectionView Methods

private extension UpcomingDateDetailViewController {
    func registerCell() {
        upcomingDateDetailContentView.dateTimeLineCollectionView.register(DateTimeLineCollectionViewCell.self, forCellWithReuseIdentifier: DateTimeLineCollectionViewCell.cellIdentifier)
    }
    
    func setDelegate() {
        upcomingDateDetailContentView.dateTimeLineCollectionView.delegate = self
        upcomingDateDetailContentView.dateTimeLineCollectionView.dataSource = self
    }

}

// MARK: - Delegate

extension UpcomingDateDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return DateDetailContentView.dateTimeLineCollectionViewLayout.itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: ScreenUtils.width * 0.112, bottom: 0, right: ScreenUtils.width * 0.112)
    }
    
}

// MARK: - DataSource

extension UpcomingDateDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return upcomingDateDetailViewModel.dateDetailData.value?.places.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let data = upcomingDateDetailViewModel.dateDetailData.value?.places[indexPath.item] else { return UICollectionViewCell() }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateTimeLineCollectionViewCell.cellIdentifier, for: indexPath) as? DateTimeLineCollectionViewCell else {
            return UICollectionViewCell() }
        cell.dataBind(data, indexPath.item)
        return cell
    }

}
