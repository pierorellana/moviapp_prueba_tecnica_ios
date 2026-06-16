import CoreData
import Foundation

@MainActor
final class CoreDataArchivedMovementStore: ArchivedMovementStoreProtocol {
    private enum Constants {
        static let modelName = "MoviAppArchive"
        static let entityName = "ArchivedMovementEntity"
        static let idKey = "id"
        static let archivedAtKey = "archivedAt"
    }

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: Constants.modelName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func fetchArchivedIDs() async throws -> Set<UUID> {
        let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
        let objects = try container.viewContext.fetch(request)

        return Set(objects.compactMap { object in
            guard let rawID = object.value(forKey: Constants.idKey) as? String else {
                return nil
            }
            return UUID(uuidString: rawID)
        })
    }

    func archive(id: UUID) async throws {
        if try contains(id: id) {
            return
        }

        guard let entity = NSEntityDescription.entity(
            forEntityName: Constants.entityName,
            in: container.viewContext
        ) else {
            return
        }

        let object = NSManagedObject(entity: entity, insertInto: container.viewContext)
        object.setValue(id.uuidString, forKey: Constants.idKey)
        object.setValue(Date(), forKey: Constants.archivedAtKey)
        try saveIfNeeded()
    }

    func unarchive(id: UUID) async throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
        request.predicate = NSPredicate(format: "%K == %@", Constants.idKey, id.uuidString)

        let objects = try container.viewContext.fetch(request)
        objects.forEach(container.viewContext.delete)
        try saveIfNeeded()
    }

    private func contains(id: UUID) throws -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", Constants.idKey, id.uuidString)
        return try !container.viewContext.fetch(request).isEmpty
    }

    private func saveIfNeeded() throws {
        guard container.viewContext.hasChanges else {
            return
        }
        try container.viewContext.save()
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = Constants.entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = Constants.idKey
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = false

        let archivedAtAttribute = NSAttributeDescription()
        archivedAtAttribute.name = Constants.archivedAtKey
        archivedAtAttribute.attributeType = .dateAttributeType
        archivedAtAttribute.isOptional = false

        entity.properties = [idAttribute, archivedAtAttribute]
        entity.uniquenessConstraints = [[Constants.idKey]]
        model.entities = [entity]

        return model
    }
}
