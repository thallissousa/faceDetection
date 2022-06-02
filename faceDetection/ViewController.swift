//
//  ViewController.swift
//  faceDetection
//
//  Created by Thallis Sousa on 31/05/22.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    let noseOptions = ["👃🏽", "🐽", "💧"]
    let eyeOptions = ["👁", "👁‍🗨"]
    
    let features = ["nose", "eye"]
    let featureIndices = [[9], [1064]]
    
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var faceLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelView.layer.cornerRadius = 10
        sceneView.delegate = self
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Este dispositivo não suporta reconhecimento facial")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if let device = sceneView.device {
            let faceMeshGeometry = ARSCNFaceGeometry(device: device)
            let node = SCNNode(geometry: faceMeshGeometry)
            node.geometry?.firstMaterial?.fillMode = .lines
            
            return node
        } else {
            fatalError("Nenhum dispositivo encontrado.")
        }
    }
    
    var analysis = ""
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
            
            expression(anchor: faceAnchor)
            DispatchQueue.main.async {
                self.faceLabel.text = self.analysis
                
                //Adicionando a transparência do Node de Nariz
                node.geometry?.firstMaterial?.transparency = 0.0
                
                //Pegando o Array de Opções de Nariz criadas logo após  a classe
                let noseNode = EmojiNode(with: self.noseOptions)
                let eyeNode = EmojiNode(with: self.eyeOptions)
                
                //Dando a correspondência de nome do nó
                noseNode.name = "nose"
                eyeNode.name = "eye"
                
                node.addChildNode(eyeNode)
                node.addChildNode(noseNode)
                
                self.updateFeatures(for: node, using: faceAnchor)
            }
            
        }
    }
    
    
    func expression (anchor: ARFaceAnchor) {
        let biquinho = anchor.blendShapes[.cheekPuff]
        let linguinha = anchor.blendShapes[.tongueOut]
        let felicidadeEsquerdo = anchor.blendShapes[.mouthSmileLeft]
        let felicidadeDireito = anchor.blendShapes[.mouthSmileRight]
        let browLeft = anchor.blendShapes[.browDownLeft]
        let browRight = anchor.blendShapes[.browDownRight]
        let browInnerUp = anchor.blendShapes[.browInnerUp]
        let jawOpen = anchor.blendShapes[.jawOpen]
        
        
        self.analysis = ""
        
        if let tipoDeBiquinho = biquinho?.decimalValue {
            if tipoDeBiquinho > 0.1 {
                //Probabilidade de detecção de uma expressão
                self.analysis += "Hmmm biquinho"
            }
        }
        
        if let tipoDeLinguinha = linguinha?.decimalValue {
            if tipoDeLinguinha > 0.1 {
                self.analysis += "li li li linguinha"
            }
        }
        
        //MARK: Felicidade
        
        if let felicidadeEsquerda = felicidadeEsquerdo?.decimalValue, let felicidadeDireita = felicidadeDireito?.decimalValue {
            if felicidadeEsquerda > 0.1 && felicidadeDireita > 0.1 {
                self.analysis += "ta felizão hein papai"
            }
        }
        
        //MARK: Surpresa
        
        if let surpresa = browInnerUp?.decimalValue, let bocaSurpresa = jawOpen?.decimalValue {
            if surpresa > 0.1 && bocaSurpresa > 0.1 {
                self.analysis = "tá em choque?"
            }
        }
        
        //MARK: Raiva
        
        if let sobrancelhaEsquerda = browLeft?.decimalValue, let sobrancelhaDireita = browRight?.decimalValue {
            if sobrancelhaEsquerda > 0.1 && sobrancelhaDireita > 0.1 {
                self.analysis = "ta bolado??"
            }
        }
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        
        for (feature, indices) in zip (features, featureIndices) {
            
            let child = node.childNode(withName: feature, recursively: false) as? EmojiNode
            
            let vertices = indices.map {
                anchor.geometry.vertices[$0]
            }
            
            child?.updatePosition(for: vertices)
            
        }
    }
}
