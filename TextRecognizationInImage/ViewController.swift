//
//  ViewController.swift
//  TextRecognizationInImage
//
//  Created by Yusai on 2022/05/28.
//

import UIKit
import Vision

class ViewController: UIViewController {

    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.text = "analyze number"
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private var resultText = ""
    private var requests = [VNRequest]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.imageView)
        self.view.addSubview(self.label)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        tap.numberOfTapsRequired = 1
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(tap)
        
        self.setupVision()
    }

    @objc func didTapImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.frame = CGRect(x: 20,
                                      y: self.view.safeAreaInsets.top,
                                      width: self.view.frame.width - 40,
                                      height: self.view.frame.width - 40)

        self.label.frame = CGRect(x: 20,
                                  y: self.view.safeAreaInsets.top + (self.view.frame.width - 40) + 10,
                                  width: self.view.frame.width - 40,
                                  height: 100)
    }

    private func setupVision() {
        let textRecognitionRequest = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let maximumCandidates = 1
            for observation in observations {
                guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                self.resultText += candidate.string
            }
        }

        textRecognitionRequest.recognitionLevel = .accurate
        self.requests = [textRecognitionRequest]
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // cancelled
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue",
                                                     qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

        textRecognitionWorkQueue.async(execute: {
            self.resultText = ""
            if let cgImage = image.cgImage {
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try requestHandler.perform(self.requests)
                } catch {
                    fatalError()
                }
            }

            DispatchQueue.main.async(execute: {
                self.imageView.image = image
                self.label.text = self.resultText
            })
        })
    }
}
