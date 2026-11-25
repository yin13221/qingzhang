import SwiftUI
import SwiftData

enum TxType: String, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }
    var title: String { self == .expense ? "支出" : "收入" }
}

enum AccountKind: String, CaseIterable, Identifiable {
    case cash
    case bank
    case alipay
    case wechat
    case credit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "现金"
        case .bank: return "银行卡"
        case .alipay: return "支付宝"
        case .wechat: return "微信"
        case .credit: return "信用卡"
        }
    }

    var symbol: String {
        switch self {
        case .cash: return "banknote.fill"
        case .bank: return "building.columns.fill"
        case .alipay: return "a.circle.fill"
        case .wechat: return "message.fill"
        case .credit: return "creditcard.fill"
        }
    }

    var color: Color {
        switch self {
        case .cash: return Color(hex: 0xF2B544)
        case .bank: return Color(hex: 0x5B8CFF)
        case .alipay: return Color(hex: 0x2AA6F0)
        case .wechat: return Color(hex: 0x2BB673)
        case .credit: return Color(hex: 0xB37BFF)
        }
    }
}

@Model
final class Account {
    var key: UUID = UUID()
    var name: String = ""
    var kindRaw: String = AccountKind.cash.rawValue
    var initialBalance: Decimal = 0
    var order: Int = 0

    init(name: String, kind: AccountKind, initialBalance: Decimal, order: Int) {
        self.key = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.initialBalance = initialBalance
        self.order = order
    }

    var kind: AccountKind { AccountKind(rawValue: kindRaw) ?? .cash }
}

@Model
final class Bill {
    var amount: Decimal
    var typeRaw: String
    var categoryID: String
    var note: String
    var date: Date
    var accountKey: UUID?
    var tags: [String] = []

    init(
        amount: Decimal,
        type: TxType,
        categoryID: String,
        note: String = "",
        date: Date = .now,
        accountKey: UUID? = nil,
        tags: [String] = []
    ) {
        self.amount = amount
        self.typeRaw = type.rawValue
        self.categoryID = categoryID
        self.note = note
        self.date = date
        self.accountKey = accountKey
        self.tags = tags
    }

    var type: TxType { TxType(rawValue: typeRaw) ?? .expense }
}

@Model
final class Transfer {
    var fromKey: UUID = UUID()
    var toKey: UUID = UUID()
    var amount: Decimal = 0
    var note: String = ""
    var date: Date = Date.now

    init(fromKey: UUID, toKey: UUID, amount: Decimal, note: String = "", date: Date = .now) {
        self.fromKey = fromKey
        self.toKey = toKey
        self.amount = amount
        self.note = note
        self.date = date
    }
}

struct TxCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
}

enum Categories {
    static let expense: [TxCategory] = [
        TxCategory(id: "food", name: "餐饮", symbol: "fork.knife", color: Color(hex: 0xFF8A66)),
        TxCategory(id: "transport", name: "交通", symbol: "car.fill", color: Color(hex: 0x5B8CFF)),
        TxCategory(id: "shopping", name: "购物", symbol: "bag.fill", color: Color(hex: 0xB37BFF)),
        TxCategory(id: "home", name: "居住", symbol: "house.fill", color: Color(hex: 0x3EC9A7)),
        TxCategory(id: "fun", name: "娱乐", symbol: "gamecontroller.fill", color: Color(hex: 0xFFB84C)),
        TxCategory(id: "health", name: "医疗", symbol: "cross.case.fill", color: Color(hex: 0xFF6B8A)),
        TxCategory(id: "study", name: "学习", symbol: "book.fill", color: Color(hex: 0x63B3ED)),
        TxCategory(id: "other", name: "其他", symbol: "ellipsis", color: Color(hex: 0x8C98AD))
    ]

    static let income: [TxCategory] = [
        TxCategory(id: "salary", name: "工资", symbol: "briefcase.fill", color: Color(hex: 0x23B98B)),
        TxCategory(id: "invest", name: "理财", symbol: "chart.line.uptrend.xyaxis", color: Color(hex: 0x5B8CFF)),
        TxCategory(id: "gift", name: "红包", symbol: "gift.fill", color: Color(hex: 0xFF8A66)),
        TxCategory(id: "otherIn", name: "其他", symbol: "ellipsis", color: Color(hex: 0x8C98AD))
    ]

    static func list(for type: TxType) -> [TxCategory] {
        type == .expense ? expense : income
    }

    static func find(_ id: String, in type: TxType) -> TxCategory {
        let all = list(for: type)
        return all.first { $0.id == id } ?? all[0]
    }
}

enum DefaultData {
    static func seedAccountsIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Account>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        let specs: [(String, AccountKind, Decimal)] = [
            ("现金", .cash, 520),
            ("银行卡", .bank, 12480),
            ("支付宝", .alipay, 1260.5),
            ("微信", .wechat, 860),
            ("信用卡", .credit, -1800)
        ]
        for (index, spec) in specs.enumerated() {
            context.insert(Account(name: spec.0, kind: spec.1, initialBalance: spec.2, order: index))
        }
        try? context.save()
    }
}

func accountBalance(_ account: Account, bills: [Bill], transfers: [Transfer]) -> Decimal {
    var value = account.initialBalance
    for bill in bills where bill.accountKey == account.key {
        value += bill.type == .income ? bill.amount : -bill.amount
    }
    for transfer in transfers {
        if transfer.fromKey == account.key { value -= transfer.amount }
        if transfer.toKey == account.key { value += transfer.amount }
    }
    return value
}