//
//  ViewController.swift
//  VideoEditing
//
//  Created by Atik Hasan on 3/26/25.
//

import UIKit
import AVKit
import Photos
import PhotosUI
import AVFoundation
import VideoEditorSDK

enum EditType {
    case filter
    case trim
    case speed
    case txtOverlay
    case faceEditor
}

class ViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var menuCollectionview: UICollectionView!
    @IBOutlet weak var filterCollectionview: UICollectionView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var filterView: UIView!{
        didSet{
            self.cnstFilterViewBottom.constant = -250
        }
    }
    @IBOutlet weak var cnstFilterViewBottom: NSLayoutConstraint!
    
    
    // MARK: - Properties
    var thumbImage : UIImage?
    var KeepTrackVideoURL : URL?
    var menuArray: [String] = ["Filter","TrimVideo","Speed","AddText","FaceEditor"]
    var filterNames = ["Luminance","Chrome","Fade","Instant","Noir","Process","Tonal","Transfer","SepiaTone","ColorClamp","ColorInvert","ColorMonochrome","SpotLight","ColorPosterize","BoxBlur","DiscBlur","GaussianBlur","MaskedVariableBlur","MedianFilter","MotionBlur","NoiseReduction"]
    var strSelectedEffect = ""
    var avplayer = AVPlayer()
    var editType : EditType = .filter
    var playerController = AVPlayerViewController()
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var selectedIndexPath: IndexPath?
    
    
    // MARK: - VC life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollectionView()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func setupCollectionView(){
        self.menuCollectionview.delegate = self
        self.menuCollectionview.dataSource = self
        self.menuCollectionview.register(MenuCVCell.nib(), forCellWithReuseIdentifier: MenuCVCell.reuseIdentifier)
        
        self.filterCollectionview.delegate = self
        self.filterCollectionview.dataSource = self
        self.filterCollectionview.register(FilterCVCell.nib(), forCellWithReuseIdentifier: FilterCVCell.reuseIdentifier)
        self.filterCollectionview.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func addVideoPlayer(videoUrl: URL, to view: UIView) {
        self.KeepTrackVideoURL = videoUrl
        self.avplayer = AVPlayer(url: videoUrl)
        playerController.player = self.avplayer
        DispatchQueue.main.async{ [self] in
            self.addChild(playerController)
            view.addSubview(playerController.view)
        }
        playerController.view.frame = view.bounds
        playerController.showsPlaybackControls = true
        self.avplayer.play()
        KeepTrackVideoURL = videoUrl
        self.thumbImage = CommonEditor.shared.generateThumbnail(path: videoUrl)
        self.filterCollectionview.reloadData()
    }
    
    func presentVideoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .any(of: [.videos])
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    func processing(){
        if editType == .filter{
            filterViewVisibility()
        }else if editType == .trim{
            avplayer.pause()
            let storyboard = UIStoryboard(name: "TrimmerViewController", bundle: nil)
            if let secondVC = storyboard.instantiateViewController(withIdentifier: "TrimmerViewController") as? TrimmerViewController {
                secondVC.videoURL = self.KeepTrackVideoURL
                secondVC.delegate = self
                secondVC.modalPresentationStyle = .fullScreen
                self.present(secondVC, animated: true, completion: nil)
            }
        }else if editType == .speed{
            avplayer.pause()
            let storyboard = UIStoryboard(name: "TrimmerViewController", bundle: nil)
            if let secondVC = storyboard.instantiateViewController(withIdentifier: "TrimmerViewController") as? TrimmerViewController {
                secondVC.videoURL = self.KeepTrackVideoURL
                secondVC.delegate = self
                secondVC.comesForSpeed = true
                secondVC.modalPresentationStyle = .fullScreen
                self.present(secondVC, animated: true, completion: nil)
            }
        }else if editType == .txtOverlay{
            
            avplayer.pause()
            let storyboard = UIStoryboard(name: "TrimmerViewController", bundle: nil)
            if let secondVC = storyboard.instantiateViewController(withIdentifier: "TrimmerViewController") as? TrimmerViewController {
                secondVC.videoURL = self.KeepTrackVideoURL
                secondVC.delegate = self
                secondVC.comesForTextOverlay = true
                secondVC.modalPresentationStyle = .fullScreen
                self.present(secondVC, animated: true, completion: nil)
            }
            
            
//            CommonEditor.shared.addTextOverlayToVideo(videoURL: KeepTrackVideoURL!) { outputURL in
//                if let outputURL = outputURL {
//                    print("Exported to: \(outputURL)")
//                    
//                } else {
//                    print("Failed to overlay text")
//                }
//            }
        }else if editType == .faceEditor{
            CommonEditor.shared.extractAllFrames(from: KeepTrackVideoURL!) { frames in
                print("🎞️ Total frames extracted: \(frames.count)")
            }
        }
    }
    
    func filterViewVisibility(){
        UIView.animate(withDuration: 0.5){
            self.cnstFilterViewBottom.constant = 0
        }
        self.view.layoutIfNeeded()
    }
    
}


extension ViewController {
    @IBAction func btnMenuAction(_ sender: Any) {
        let alert = UIAlertController(title: "Menu", message: "Choose an option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.presentVideoPicker()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad support (optional but important)
        if let popoverController = alert.popoverPresentationController {
            if let button = sender as? UIView {
                popoverController.sourceView = button
                popoverController.sourceRect = button.bounds
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnCheckMarkAction() {
       // self.avplayer.replaceCurrentItem(with: nil)
        UIView.animate(withDuration: 0.5) {
            self.cnstFilterViewBottom.constant = -250
        }

        guard let KeepTrackVideoURL = KeepTrackVideoURL else { return }
        if strSelectedEffect == ""{
            //self.addVideoPlayer(videoUrl: KeepTrackVideoURL, to: self.playerView)
           // return
        }else{
            self.avplayer.pause()
            print("KeepTrackVideoURL : ", KeepTrackVideoURL)
            CommonEditor.shared.addfiltertoVideo(strfiltername: strSelectedEffect, strUrl: KeepTrackVideoURL, success: { url in
                DispatchQueue.main.async {
                    print("success")
                    self.addVideoPlayer(videoUrl: url, to: self.playerView)
                    self.KeepTrackVideoURL = url
                }
            }, failure: { error in
                DispatchQueue.main.async {
                    print("add filter to video error is \(String(describing: error))")
                }
            })
        }

        self.filterView.layoutIfNeeded()
    }

    
    @IBAction func btnCloseMarkAction(){
        UIView.animate(withDuration: 0.5){
            self.cnstFilterViewBottom.constant = -250
        }
        self.filterView.layoutIfNeeded()
    }
}

// MARK: - CollectionView Delegate & DataSource
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == menuCollectionview{
            return menuArray.count
        }else if collectionView == filterCollectionview{
            return filterNames.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == menuCollectionview{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuCVCell.reuseIdentifier, for: indexPath) as! MenuCVCell
            cell.iamgeView.image = UIImage(named: menuArray[indexPath.row])
            cell.lblTitle.text = menuArray[indexPath.row]
            return cell
        }else if collectionView == filterCollectionview{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCVCell.reuseIdentifier, for: indexPath) as! FilterCVCell
            cell.lblTitle.text = filterNames[indexPath.row]
            if let thumbImage = thumbImage {
                cell.imageView.image = CommonEditor.shared.convertImageToBW(filterName: CommonEditor.shared.CIFilterNames[indexPath.row], image: thumbImage)
            }
            cell.imageView.layer.masksToBounds = true
            cell.imageView.layer.cornerRadius = 5
            
            if indexPath == selectedIndexPath {
                cell.bgView.layer.cornerRadius = 5
                cell.bgView.layer.borderWidth = 2
                cell.bgView.layer.borderColor = UIColor.white.cgColor
            } else {
                cell.bgView.layer.cornerRadius = 0
                cell.bgView.layer.borderWidth = 0
                cell.bgView.layer.borderColor = UIColor.clear.cgColor
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == menuCollectionview{
            return CGSize(width: 60, height: 60)
        }else{
            return CGSize(width: 80, height: collectionView.bounds.height)
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let url = KeepTrackVideoURL else{ return }
        if collectionView == menuCollectionview{
            switch indexPath.row {
            case 0:
                self.editType = .filter
            case 1:
                self.editType = .trim
            case 2:
                self.editType = .speed
            case 3:
                self.editType = .txtOverlay
            case 4:
                self.editType = .faceEditor
            default:
                break
            }
            processing()
        }else if collectionView == filterCollectionview{
            self.strSelectedEffect = CommonEditor.shared.CIFilterNames[indexPath.row]
            
            if let previous = selectedIndexPath, previous != indexPath {
                selectedIndexPath = indexPath
                collectionView.reloadItems(at: [previous, indexPath])
            } else {
                selectedIndexPath = indexPath
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}


extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first,
              result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
            return
        }
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
            if let url = url {
                // Copy the video to a temporary location
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    
                    DispatchQueue.main.async {
                        print("Video URL: \(tempURL)")
                        self.avplayer.pause()
                        self.addVideoPlayer(videoUrl: tempURL, to: self.playerView)
                    }
                } catch {
                    print("Error copying video: \(error)")
                }
            } else if let error = error {
                print("Error loading video: \(error)")
            }
        }
    }
}


extension ViewController : VideoSelectionDelegate{
    func didSelectVideo(url: URL) {
        self.KeepTrackVideoURL = url
        DispatchQueue.main.asyncAfter(deadline: .now()+3){
            self.addVideoPlayer(videoUrl: url, to: self.playerView)
        }
    }
}




//
////
////  TrimmerViewController.swift
////  VideoEditing
////
////  Created by Atik Hasan on 4/9/25.
////
//
//import UIKit
//import AVKit
//import AVFoundation
//
//protocol VideoSelectionDelegate: AnyObject {
//    func didSelectVideo(url: URL)
//}
//
//struct TransformInfo {
//    var translation: CGPoint = .zero
//    var scale: CGFloat = 1.0
//    var rotation: CGFloat = 0.0
//}
//
//class TrimmerViewController: UIViewController {
//    
//    var speedCollectionView: UICollectionView!
//    let playerController = AVPlayerViewController()
//    var videoURL : URL?
//    var trimmer: VideoTrimmer!
//    var timingStackView: UIStackView!
//    var leadingTrimLabel: UILabel!
//    var currentTimeLabel: UILabel!
//    var trailingTrimLabel: UILabel!
//    var overlayTransformInfo = TransformInfo()
//
//    
//    let playerView = UIView()
//    var avplayer = AVPlayer()
//    private var wasPlaying = false
//    var comesForSpeed: Bool = false
//    var comesForTextOverlay = false
//    weak var delegate: VideoSelectionDelegate?
//   // private var player: AVPlayer! {playerController.player}
//    private var player: AVPlayer!
//    private var asset: AVAsset!
//    var startTimeString = ""
//    var endTimeString = ""
//    var speedRate: Float64 = 1.0
//    let speedOptions: [String] = ["0.5","1.0","1.5","2.0","2.5"]
//    var selectedIndexPath: IndexPath? = IndexPath(item: 1, section: 0)
//    
//    
//    // MARK: - Input
//    @objc private func didBeginTrimming(_ sender: VideoTrimmer) {
//        updateLabels()
//        
//        wasPlaying = (player.timeControlStatus != .paused)
//        player.pause()
//        
//        updatePlayerAsset()
//    }
//    
//    @objc private func didEndTrimming(_ sender: VideoTrimmer) {
//        updateLabels()
//        
//        if wasPlaying == true {
//            player.play()
//        }
//        
//        updatePlayerAsset()
//    }
//    
//    @objc private func selectedRangeDidChanged(_ sender: VideoTrimmer) {
//        updateLabels()
//    }
//    
//    @objc private func didBeginScrubbing(_ sender: VideoTrimmer) {
//        updateLabels()
//        
//        wasPlaying = (player.timeControlStatus != .paused)
//        player.pause()
//    }
//    
//    @objc private func didEndScrubbing(_ sender: VideoTrimmer) {
//        updateLabels()
//        
//        if wasPlaying == true {
//            player.play()
//        }
//    }
//    
//    @objc private func progressDidChanged(_ sender: VideoTrimmer) {
//        updateLabels()
//        
//        let time = CMTimeSubtract(trimmer.progress, trimmer.selectedRange.start)
//        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
//    }
//    
//    // MARK: - Private
//    private func updateLabels() {
//        self.startTimeString = trimmer.selectedRange.start.displayString
//        leadingTrimLabel.text = startTimeString
//        currentTimeLabel.text = trimmer.progress.displayString
//        self.endTimeString  = trimmer.selectedRange.end.displayString
//        trailingTrimLabel.text = endTimeString
//    }
//    
//    private func updatePlayerAsset() {
//        let outputRange = trimmer.trimmingState == .none ? trimmer.selectedRange : asset.fullRange
//        let trimmedAsset = asset.trimmedComposition(outputRange)
//        if trimmedAsset != player.currentItem?.asset {
//            player.replaceCurrentItem(with: AVPlayerItem(asset: trimmedAsset))
//        }
//    }
//    
//    // MARK: - UIViewController
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.setupCollectionView()
//        self.setupPlayerView()
//        self.setupUI()
//        if comesForSpeed {
//            self.speedCollectionView.isHidden = false
//        }else if comesForTextOverlay{
//            self.speedCollectionView.isHidden = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) { [self] in
//                let textView = UITextView()
//                textView.delegate = self
//                textView.textAlignment = .center
//                textView.backgroundColor = UIColor.yellow
//                textView.textColor = .red
//                textView.font = UIFont.boldSystemFont(ofSize: 32)
//                textView.isHidden = true
//                textView.isScrollEnabled = false
//                
//                playerController.view.addSubview(textView)
//                
//                // layout
//                textView.translatesAutoresizingMaskIntoConstraints = false
//                let heightConstraint = textView.heightAnchor.constraint(equalToConstant: 50)
//                NSLayoutConstraint.activate([
//                    textView.topAnchor.constraint(equalTo: playerController.view.topAnchor, constant: 0),
//                    textView.leadingAnchor.constraint(equalTo: playerController.view.leadingAnchor, constant: 0),
//                    textView.trailingAnchor.constraint(equalTo: playerController.view.trailingAnchor, constant: 0),
//                    heightConstraint
//                ])
//                
//                textView.isHidden = false
//                textView.becomeFirstResponder()
//                
//                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
//                tapGesture.cancelsTouchesInView = false
//                view.addGestureRecognizer(tapGesture)
//                
//                let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
//                textView.addGestureRecognizer(pinchGesture)
//                
//                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//                textView.addGestureRecognizer(panGesture)
//                
//                let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
//                textView.addGestureRecognizer(rotationGesture)
//            }
//        }
//        else{
//            self.speedCollectionView.isHidden = true
//        }
//        
//    }
//    
//    func addVideoPlayer(videoUrl: URL, to view: UIView) {
//        self.player = AVPlayer(url: videoUrl)
//        playerController.player = self.player
//        playerController.showsPlaybackControls = true
//
//        DispatchQueue.main.async {
//            self.addChild(self.playerController)
//            view.addSubview(self.playerController.view)
//            self.playerController.view.frame = view.bounds
//            self.playerController.didMove(toParent: self)
//            self.player.play()
//        }
//    }
//    
//    func setupPlayerView(){
//        playerView.backgroundColor = .blue
//        playerView.translatesAutoresizingMaskIntoConstraints = false
//        self.view.addSubview(playerView)
//        
//        NSLayoutConstraint.activate([
//            playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            playerView.widthAnchor.constraint(equalTo: view.widthAnchor),
//            playerView.heightAnchor.constraint(equalToConstant: 300)
//        ])
//    }
//    
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
//    
//    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//        guard let viewToResize = gesture.view else { return }
//
//        if gesture.state == .changed || gesture.state == .ended {
//            let scaledTransform = viewToResize.transform.scaledBy(x: gesture.scale, y: gesture.scale)
//            viewToResize.transform = scaledTransform
//            overlayTransformInfo.scale *= gesture.scale
//            gesture.scale = 1.0
//        }
//    }
//
//    
//    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
//        guard let viewToMove = gesture.view else { return }
//        let translation = gesture.translation(in: view)
//        viewToMove.center = CGPoint(x: viewToMove.center.x + translation.x, y: viewToMove.center.y + translation.y)
//        overlayTransformInfo.translation.x += translation.x
//        overlayTransformInfo.translation.y += translation.y
//        gesture.setTranslation(.zero, in: view)
//    }
//
//    
//    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
//        guard let viewToRotate = gesture.view else { return }
//
//        if gesture.state == .began || gesture.state == .changed {
//            viewToRotate.transform = viewToRotate.transform.rotated(by: gesture.rotation)
//            overlayTransformInfo.rotation += gesture.rotation
//            gesture.rotation = 0
//        }
//    }
//
//
//}
//
//extension TrimmerViewController {
//    func setupUI(){
//        view.backgroundColor = .black
//        guard let videoURL = videoURL else { return }
//        
//        asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
//        
//        // THIS IS WHERE WE SETUP THE VIDEOTRIMMER:
//        trimmer = VideoTrimmer()
//        trimmer.minimumDuration = CMTime(seconds: 1, preferredTimescale: 600)
//        trimmer.addTarget(self, action: #selector(didBeginTrimming(_:)), for: VideoTrimmer.didBeginTrimming)
//        trimmer.addTarget(self, action: #selector(didEndTrimming(_:)), for: VideoTrimmer.didEndTrimming)
//        trimmer.addTarget(self, action: #selector(selectedRangeDidChanged(_:)), for: VideoTrimmer.selectedRangeChanged)
//        trimmer.addTarget(self, action: #selector(didBeginScrubbing(_:)), for: VideoTrimmer.didBeginScrubbing)
//        trimmer.addTarget(self, action: #selector(didEndScrubbing(_:)), for: VideoTrimmer.didEndScrubbing)
//        trimmer.addTarget(self, action: #selector(progressDidChanged(_:)), for: VideoTrimmer.progressChanged)
//        view.addSubview(trimmer)
//        trimmer.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            trimmer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//            trimmer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
//            trimmer.topAnchor.constraint(equalTo: playerController.view.bottomAnchor, constant: 16),
//            trimmer.heightAnchor.constraint(equalToConstant: 50),
//        ])
//        
//        leadingTrimLabel = UILabel()
//        leadingTrimLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
//        leadingTrimLabel.textAlignment = .left
//        leadingTrimLabel.textColor = .white
//        
//        currentTimeLabel = UILabel()
//        currentTimeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
//        currentTimeLabel.textAlignment = .center
//        currentTimeLabel.textColor = .white
//        
//        
//        trailingTrimLabel = UILabel()
//        trailingTrimLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
//        trailingTrimLabel.textAlignment = .right
//        trailingTrimLabel.textColor = .white
//        
//        
//        timingStackView = UIStackView(arrangedSubviews: [leadingTrimLabel, currentTimeLabel, trailingTrimLabel])
//        timingStackView.axis = .horizontal
//        timingStackView.alignment = .fill
//        timingStackView.distribution = .fillEqually
//        timingStackView.spacing = UIStackView.spacingUseSystem
//        view.addSubview(timingStackView)
//        timingStackView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            timingStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
//            timingStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
//            timingStackView.topAnchor.constraint(equalTo: trimmer.bottomAnchor, constant: 8),
//        ])
//        
//        trimmer.asset = asset
//        updatePlayerAsset()
//        
//        player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) { [weak self] time in
//            guard let self = self else {return}
//            // when we're not trimming, the players starting point is actual later than the trimmer,
//            // (because the vidoe has been trimmed), so we need to account for that.
//            // When we're trimming, we always show the full video
//            let finalTime = self.trimmer.trimmingState == .none ? CMTimeAdd(time, self.trimmer.selectedRange.start) : time
//            self.trimmer.progress = finalTime
//        }
//        ActivityIndicatorManager.shared.showLoader(on: self.view)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
//            ActivityIndicatorManager.shared.hideLoader()
//            self.addVideoPlayer(videoUrl: videoURL, to: playerView)
//            //player.play()
//        }
//        updateLabels()
//        
//        speedCollectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
//    }
//    
//    
//    func setupCollectionView(){
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        layout.minimumInteritemSpacing = 10
//        layout.estimatedItemSize = .zero
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
//        
//        speedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        speedCollectionView.translatesAutoresizingMaskIntoConstraints = false
//        speedCollectionView.backgroundColor = .black
//        speedCollectionView.showsHorizontalScrollIndicator = false
//        
//        speedCollectionView.delegate = self
//        speedCollectionView.dataSource = self
//        self.speedCollectionView.register(SpeedCell.nib(), forCellWithReuseIdentifier: SpeedCell.reuseIdentifier)
//        
//        view.addSubview(speedCollectionView)
//        
//        NSLayoutConstraint.activate([
//            speedCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10),
//            speedCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            speedCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            speedCollectionView.heightAnchor.constraint(equalToConstant: 60)
//        ])
//    }
//    
//    
//    func timeStringToCMTime(_ timeString: String) -> CMTime {
//        let components = timeString.split(separator: ":").map { Double($0) ?? 0 }
//        
//        var seconds: Double = 0
//        if components.count == 3 {
//            // HH:MM:SS
//            seconds = components[0] * 3600 + components[1] * 60 + components[2]
//        } else if components.count == 2 {
//            // MM:SS
//            seconds = components[0] * 60 + components[1]
//        } else if components.count == 1 {
//            // SS
//            seconds = components[0]
//        }
//        
//        return CMTime(seconds: seconds, preferredTimescale: 600)
//    }
//    
//    private func playVideo(from url: URL) {
//        let playerItem = AVPlayerItem(url: url)
//        player.replaceCurrentItem(with: playerItem)
//        player.play()
//    }
//}
//
//
//// MARK: - Action Methods
//extension TrimmerViewController {
//    
//    @IBAction func btnCheckMarkAction(){
//        ActivityIndicatorManager.shared.showLoader(on: self.view)
//        self.player.pause()
//        let startTime = timeStringToCMTime(startTimeString)
//        let endTime = timeStringToCMTime(endTimeString)
//        
//        if comesForSpeed {
//            CommonEditor.shared.changeVideoSpeedInRange(url: videoURL!, startTime: startTime, endTime: endTime, speed: speedRate) { [self] newURL in
//                if let finalURL = newURL {
//                    print("Done: \(finalURL)")
//                    delegate?.didSelectVideo(url: finalURL)
//                } else {
//                    print("Failed to export")
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now()+3){
//                    ActivityIndicatorManager.shared.hideLoader()
//                    self.dismiss(animated: true)
//                }
//            }
//        }else if comesForTextOverlay {
//            guard let videoURL = videoURL,
//                  let textView = playerController.view.subviews.first(where: { $0 is UITextView }) as? UITextView else {
//                print("Video or TextView missing")
//                return
//            }
//            
//            CommonEditor.shared.addTextOverlayToVideo(videoURL: videoURL,
//                                                      overlayTextView: textView, transformInfo: overlayTransformInfo,
//                                                      startTime: startTime,
//                                                      endTime: endTime) { [self] exportedURL in
//                if let url = exportedURL {
//                    print("Export complete! URL: \(url)")
//                    delegate?.didSelectVideo(url: url)
//                    DispatchQueue.main.asyncAfter(deadline: .now()+3){
//                        ActivityIndicatorManager.shared.hideLoader()
//                        self.dismiss(animated: true)
//                    }
//                    // Optional: Share or show success alert
//                } else {
//                    print("Export failed")
//                }
//            }
//        }
//        else{
//            CommonEditor.shared.trimVideo(sourceURL: videoURL!, startTime: startTime, endTime: endTime) { [self] trimmedURL in
//                if let url = trimmedURL {
//                    delegate?.didSelectVideo(url: url)
//                } else {
//                    print("Trimming failed.")
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now()+3){
//                    ActivityIndicatorManager.shared.hideLoader()
//                    self.dismiss(animated: true)
//                }
//            }
//        }
//        comesForSpeed = false
//        comesForTextOverlay = false
//    }
//    
//    @IBAction func btnDismissAction(){
//        self.player.pause()
//        comesForSpeed = false
//        comesForTextOverlay = false
//        self.dismiss(animated: true)
//    }
//}
//
//
//// MARK: - CollectionView Delegate & DataSource
//extension TrimmerViewController: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return speedOptions.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpeedCell.reuseIdentifier, for: indexPath) as! SpeedCell
//        cell.speedLabel.text = speedOptions[indexPath.row]
//        
//        if indexPath == selectedIndexPath {
//            cell.bgView.backgroundColor = .red
//        } else {
//            cell.bgView.backgroundColor = .white
//        }
//        
//        return cell
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 60, height: 40)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 10
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 10
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        self.speedRate = Float64(speedOptions[indexPath.row])!
//        print(speedRate)
//        if let previous = selectedIndexPath, previous != indexPath {
//            selectedIndexPath = indexPath
//            collectionView.reloadItems(at: [previous, indexPath])
//        } else {
//            selectedIndexPath = indexPath
//            collectionView.reloadItems(at: [indexPath])
//        }
//    }
//    
//}
//
//
//extension TrimmerViewController : UITextViewDelegate{
//    func textViewDidChange(_ textView: UITextView) {
//        let size = CGSize(width: textView.frame.width, height: .infinity)
//        let estimatedSize = textView.sizeThatFits(size)
//
//        textView.constraints.forEach { constraint in
//            if constraint.firstAttribute == .height {
//                constraint.constant = estimatedSize.height
//            }
//        }
//        self.view.layoutIfNeeded()
//    }
//}
