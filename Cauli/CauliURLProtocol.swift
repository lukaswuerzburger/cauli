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

import Foundation

internal class CauliURLProtocol: URLProtocol {
    // We are keeping this as implicitly unwrapped optional so we can initialize it
    // right after the super.init with self as the delegate
    // swiftlint:disable implicitly_unwrapped_optional
    private var executingURLSession: URLSession!
    // swiftlint:enable implicitly_unwrapped_optional

    private static var weakDelegates: [WeakReference<CauliURLProtocolDelegate>] = []
    private static var delegates: [CauliURLProtocolDelegate] {
        let nonNilDelegates = weakDelegates.filter { $0.value != nil }
        return nonNilDelegates.compactMap { $0.value as? CauliURLProtocolDelegate }
    }

    private var record: Record
    private var dataTask: URLSessionDataTask?

    internal static func add(delegate: CauliURLProtocolDelegate) {
        weakDelegates.append(WeakReference(delegate))
    }

    internal static func remove(delegate: CauliURLProtocolDelegate) {
        weakDelegates = weakDelegates.filter { $0.value !== delegate }
    }

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        record = Record(request)
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter { $0 != CauliURLProtocol.self }
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        executingURLSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
}

// Overriding URLProtocol functions
extension CauliURLProtocol {

    override class func canInit(with task: URLSessionTask) -> Bool {
        return task is URLSessionDataTask && !delegates.isEmpty
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return !delegates.isEmpty
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        CauliURLProtocol.delegates.cauli_reduceAsync(record, transform: { record, delegate, completion in
            delegate.willRequest(record) { record in
                completion(record)
            }
        }, completion: { record in
            if case let .result(response) = record.result {
                self.client?.urlProtocol(self, didReceive: response.urlResponse, cacheStoragePolicy: .allowed)
                if let data = response.data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            } else if case let .error(error) = record.result {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                self.dataTask = self.executingURLSession.dataTask(with: self.request)
                self.dataTask?.resume()
            }
        })
    }

    override func stopLoading() {
        dataTask?.cancel()
    }
}

extension CauliURLProtocol: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        record.result = .result(Response(response, data: nil))
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive receivedData: Data) {
        try? record.append(receivedData)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            record.result = .error(error as NSError)
        }

        CauliURLProtocol.delegates.cauli_reduceAsync(record, transform: { record, delegate, completion in
            delegate.didRespond(record) { record in
                completion(record)
            }
        }, completion: { record in
            switch record.result {
            case let .result(response):
                self.client?.urlProtocol(self, didReceive: response.urlResponse, cacheStoragePolicy: .allowed)
                if let data = response.data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            case .error(let error):
                self.client?.urlProtocol(self, didFailWithError: error)
            case .none:
                self.client?.urlProtocol(self, didFailWithError: NSError(domain: "FIXME", code: 0, userInfo: [:]))
            }
        })
    }

    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // possibly add the metrics to the record in the future
    }
}
