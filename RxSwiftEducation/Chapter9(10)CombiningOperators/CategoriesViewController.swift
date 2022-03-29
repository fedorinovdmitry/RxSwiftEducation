
import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx

class CategoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    private let categories = BehaviorRelay<[EOCategory]>(value: [])
    
    var activityIndicator: UIActivityIndicatorView!
    let download = DownloadView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        
        view.addSubview(download)
        view.layoutIfNeeded()
        
        categories
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView?.reloadData()
                }
            })
            .disposed(by: rx.disposeBag)
        startDownload()
    }
    
    func startDownload() {
        
        // CHALLENGE 2
        download.progress.progress = 0.0
        download.label.text = "Download: 0%"
        
        let eoCategories = EONET.categories
        let downloadedEvents = eoCategories
            .flatMap { categories in
                return Observable.from(categories.map { category in EONET.events(forLast: 360, category: category)})
            }
            .merge(maxConcurrent: 2)
        
        let updatedCategories = eoCategories.flatMap { categories in
            downloadedEvents.scan(categories) { updated, events in
                return updated.map { category in
                    let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
                    if !eventsForCategory.isEmpty {
                        var cat = category
                        cat.events = cat.events + eventsForCategory
                        return cat
                    }
                    return category
                }
            }
        }
        // CHALLENGE 1
            .do(onCompleted: { [weak self] in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    // CHALLENGE 2
                    self?.download.isHidden = true
                }
            })
                
                // CHALLENGE 2
                eoCategories.flatMap { categories in
                    return updatedCategories.scan(0) { count, _ in return count + 1 }
                    .startWith(0)
                    .map { ($0, categories.count) }
                }
                .subscribe(onNext: { tuple in
                    DispatchQueue.main.async { [weak self] in
                        let progress = Float(tuple.0) / Float(tuple.1)
                        self?.download.progress.progress = progress
                        let percent = Int(progress * 100.0)
                        self?.download.label.text = "Download: \(percent)%"
                    }
                })
                .disposed(by: rx.disposeBag)
        
        eoCategories
            .concat(updatedCategories)
            .bind(to: categories)
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        let category = categories.value[indexPath.row]
        cell.textLabel?.text = category.name
        cell.detailTextLabel?.text = category.description
        cell.textLabel?.text = "\(category.name) (\(category.events.count))"
        cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories.value[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard !category.events.isEmpty else { return }
        let eventsController =
        storyboard!.instantiateViewController(withIdentifier: "events") as! EventsViewController
        eventsController.title = category.name
        eventsController.events.accept(category.events)
        navigationController!.pushViewController(eventsController, animated: true)
    }
    
}

