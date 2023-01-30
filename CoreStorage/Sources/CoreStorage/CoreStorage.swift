import SwiftUI
import CoreData
import Combine

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@propertyWrapper
public struct CoreStorage<Object: NSManagedObject>: DynamicProperty {
    @Environment(\.managedObjectContext) public var viewContext
    
    public var wrappedValue: FetchedResults<Object> { self.fetchRequest.wrappedValue }
    public var projectedValue: CoreStorage { self }

    public var fetchRequest: FetchRequest<Object>
    public var hasChanges: Bool = false
    public var autoSave: Bool
    
    /// Designated initializer
    public init(with predicate: NSPredicate? = nil, sorters: [NSSortDescriptor] = [], autoSave: Bool = true) where Object: NSManagedObject {
        if let predicate = predicate {
            self.fetchRequest = FetchRequest<Object>(entity: Object.entity(), sortDescriptors: sorters, predicate: predicate)
        } else {
            self.fetchRequest = FetchRequest<Object>(entity: Object.entity(), sortDescriptors: sorters, predicate: nil)
        }
        self.autoSave = autoSave
    }
    
    public func deleteItems(at offsets: IndexSet) {
        offsets.map {
            self.wrappedValue[$0]
        }
        .forEach(self.viewContext.delete)
        
        if self.autoSave {
            self.save()
        }
    }
    
    public func deleteAll() {
        self.wrappedValue.forEach(self.viewContext.delete(_:))
        if self.autoSave {
            self.save()
        }
    }
    
    public func publisher() -> AnyPublisher<Bool, Never> {
        self.wrappedValue.publisher
            .compactMap { results in
                results.hasChanges
            }
            .eraseToAnyPublisher()
    }
    
    public func save() {
        if self.viewContext.hasChanges {
            try? self.viewContext.save()
        }
    }
}
