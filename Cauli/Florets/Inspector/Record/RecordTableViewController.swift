//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

class RecordTableViewController: UITableViewController {

    let record: Record
    let datasource: RecordTableViewDatasource
    lazy var shareButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped))
    }()

    init(_ record: Record) {
        self.record = record
        self.datasource = RecordTableViewDatasource(record)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Record"
        datasource.setup(tableView)
        tableView.dataSource = datasource
        navigationItem.rightBarButtonItem = shareButton
    }

    @objc func shareButtonTapped() {
        guard let tempPath = MockRecordSerializer.write(record: record) else { return }

        let allRecordFiles = (try? FileManager.default.contentsOfDirectory(at: tempPath, includingPropertiesForKeys: nil, options: [])) ?? []

        let viewContoller = UIActivityViewController(activityItems: allRecordFiles, applicationActivities: nil)
        present(viewContoller, animated: true, completion: nil)
    }

}

// UITableViewDelegate
extension RecordTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = datasource.item(at: indexPath) else { return }

        let activityItem = item.value() ?? item.description

        let viewContoller = UIActivityViewController(activityItems: [activityItem], applicationActivities: nil)
        present(viewContoller, animated: true, completion: nil)
    }
}