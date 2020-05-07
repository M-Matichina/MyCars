//
//  ViewController.swift
//  MyCars
//
//  Created by Мария Матичина on 4/29/20.
//  Copyright © 2020 Мария Матичина. All rights reserved.
//



import UIKit
import CoreData

class ViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet { // блок отрабатывает когда segmentedControl будет инициализирован
            updateSegmentedControl()
            
            // Внутри segmentedControl - белый
            segmentedControl.selectedSegmentTintColor = .white
            
            // Текст segmentedControl
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            // foreground - передний план
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            
            // Segment выделен текст - черный
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
        }
    }
    
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    // MARK: - Properties
    
    /*
     lazy var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
     обращение к AppDelegate к persistentContainer к viewContext, но это не обязательно делать, если мы можем передавать viewContext из ViewController в другой ViewController
     */
    
    var context: NSManagedObjectContext!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        return df
    } ()
    
    var car: Car!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         if let isWasFirstLaunch = UserDefaults.standard.value(forKey: "isWasFirstLaunch") as? Bool, isWasFirstLaunch {
         } else {
         getDataFromFile()
         }
         
         UserDefaults - сохраняете пары ключ-значение при запуске вашего приложения.
         */
        
        getDataFromFile()
    }
    
    
    // MARK: - Actions
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentedControl()
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1 // увелич. кол-во поездок
        car.lastStarted = Date() // после обновляем дату поездки
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print (error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertControlller = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            // достаем текст из текстового поля и подставляем в качесте нового значения для rate нашего авто
            if let text = alertControlller.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue) // преобразуем в Double
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        // Добавляем текстовое поле
        alertControlller.addTextField { (textField) in
            textField.keyboardType = .numberPad // ввод только цифр
        }
        
        alertControlller.addAction(rateAction)
        alertControlller.addAction(cancelAction)
        
        present(alertControlller, animated: true, completion: nil)
    }
    
    
    // MARK: - Configure
    
    // MARK: - updateSegmentedControl
    private func updateSegmentedControl() {
        
        // Машину выбираем по марке
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) ?? ""
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark)
        // %@ является аргументом замещения для объекта обозначающим чаще всего строку, число или дату
        
        
        
        
        do {
            let results = try context.fetch(fetchRequest)
            if let carResult = results.first {
                car = carResult
                insertDataFrom(selectedCar: car)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: - func update
    private func update(rating: Double) {
        car.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            // При ошибке (введено неверное значение), появляется alertСontroller
            let alertcontroller = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default)
            
            alertcontroller.addAction(okAction)
            present(alertcontroller, animated: true, completion: nil)
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: Вставляем наши данные в интерфейс приложения
    private func insertDataFrom(selectedCar car: Car) {
        
        if let imageData = car.imageData {
            carImageView.image = UIImage(data: imageData)
        }
        
        markLabel.text = car.mark
        modelLabel.text = car.model
        
        myChoiceImageView.isHidden = car.myChoice == false // = !(car.myChoice)   // !true or false equal
        
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        
        if let lastTimeStarted = car.lastStarted {
            lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: lastTimeStarted))"
        }
        
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    
    // MARK:- извлекаем данные
    private func getDataFromFile() {
        
        
        // MARK: При каждой загрузке проверяем есть ли уже какая-то ифно (через CoreData)
        // Получаем все записи типа Car
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil") // получаем записи, у которых mark != nil.  Все марки подписаны
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest) // records - записи
            print("Is Data there already?")
        } catch let error as NSError {
            print(error.localizedDescription)
            // localizedDescription - строка, содержащая локализованное описание ошибки
        }
        
        // Сколько записей в var records
        guard records == 0 else {return}
        
        // Получаем путь к нащему file
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
            
            /*
             Bundle - представление кода и ресурсов, хранящихся в пакете на диске.
             Main - возвращает объект пакета, который содержит текущий исполняемый файл.
             */
            
            // Извлекаем массив
            let dataArray = NSArray(contentsOfFile: pathToFile) else { return }
        
        // Берем данные из массива и помещаем в CoreData
        for dictionary in dataArray {
            
            // Создаем объекты
            guard let entity = NSEntityDescription.entity(forEntityName: "Car", in: context),
                let car = NSManagedObject(entity: entity, insertInto: context) as? Car else { return }
            
            
            let carDictionary = dictionary as! [String : AnyObject]
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            // image
            if let imageName = carDictionary["imageName"] as? String, let image = UIImage(named: imageName) {
                let imageData = image.pngData() // возвращает в формате png
                car.imageData = imageData
            }
            
            // color
            if let colorDictionary = carDictionary["tintColor"] as? [String : Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary) // получить цвет в виде массива
            }
            
        }
    }
    
    
    // MARK:- получаем цвет (color)
    private func getColor(colorDictionary: [String : Float]) -> UIColor {
        // Извлекаем значения RGB
        guard let red = colorDictionary["red"],
            let green = colorDictionary["green"],
            let blue = colorDictionary["blue"] else { return UIColor() } // в противном случаи пустой цвет
        
        // Если получилось, то
        return UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: 1.0)
        // 1.0 - не прозрачный
    }
}

