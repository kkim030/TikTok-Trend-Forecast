import Foundation

// MARK: - Auth
struct AuthResponse: Codable {
    let token: String
    let userId: UUID
    let email: String
    let fullName: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let fullName: String
}

// MARK: - Account
enum AccountType: String, Codable, CaseIterable {
    case TFSA, FHSA, RRSP, CASH, MARGIN

    var displayName: String {
        switch self {
        case .TFSA: return "TFSA"
        case .FHSA: return "FHSA"
        case .RRSP: return "RRSP"
        case .CASH: return "Cash"
        case .MARGIN: return "Margin"
        }
    }

    var icon: String {
        switch self {
        case .TFSA: return "leaf.fill"
        case .FHSA: return "house.fill"
        case .RRSP: return "building.columns.fill"
        case .CASH: return "dollarsign.circle.fill"
        case .MARGIN: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Quick Actions
enum QuickAction: CaseIterable {
    case placeOrder, viewOrderStatus, viewActivity, viewWatchlists

    var displayName: String {
        switch self {
        case .placeOrder: return "Place Order"
        case .viewOrderStatus: return "View Order Status"
        case .viewActivity: return "View Activity"
        case .viewWatchlists: return "View Watchlists"
        }
    }

    var icon: String {
        switch self {
        case .placeOrder: return "arrow.left.arrow.right"
        case .viewOrderStatus: return "list.bullet.clipboard"
        case .viewActivity: return "chart.bar.doc.horizontal"
        case .viewWatchlists: return "star"
        }
    }
}

struct AccountSummary: Codable, Identifiable {
    let id: UUID
    let accountNumber: String
    let accountType: AccountType
    let currency: String
    let cashBalance: Double
    let holdingsValue: Double
    let totalValue: Double
    let totalGainLoss: Double
    let totalGainLossPercent: Double
}

// MARK: - Holding
struct Holding: Codable, Identifiable {
    let id: UUID
    let accountId: UUID
    let symbol: String
    let exchange: String
    let quantity: Double
    let avgCost: Double
    let bookValue: Double
    let currency: String
    let currentPrice: Double?
    let marketValue: Double?
    let gainLoss: Double?
    let gainLossPercent: Double?
    let dayChange: Double?
    let dayChangePercent: Double?
}

// MARK: - Order
enum OrderSide: String, Codable, CaseIterable {
    case BUY, SELL, SHORT, COVER
    var color: String {
        switch self {
        case .BUY, .COVER: return "green"
        case .SELL, .SHORT: return "red"
        }
    }
}

enum OrderType: String, Codable, CaseIterable {
    case MARKET, LIMIT, STOP, STOP_LIMIT
    var displayName: String {
        switch self {
        case .MARKET: return "Market"
        case .LIMIT: return "Limit"
        case .STOP: return "Stop"
        case .STOP_LIMIT: return "Stop Limit"
        }
    }
}

enum OrderStatus: String, Codable {
    case PENDING, FILLED, PARTIAL, CANCELLED, REJECTED
    var color: String {
        switch self {
        case .FILLED: return "green"
        case .PENDING, .PARTIAL: return "orange"
        case .CANCELLED, .REJECTED: return "red"
        }
    }
}

enum OrderDuration: String, Codable, CaseIterable {
    case DAY, GTC, GTD
    var displayName: String {
        switch self {
        case .DAY: return "Day"
        case .GTC: return "Good Till Cancelled"
        case .GTD: return "Good Till Date"
        }
    }
}

struct OrderRequest: Codable {
    let accountId: UUID
    let symbol: String
    var exchange: String = "TSX"
    let side: OrderSide
    let orderType: OrderType
    let quantity: Double
    var limitPrice: Double?
    var stopPrice: Double?
    var duration: OrderDuration = .DAY
}

struct OrderResponse: Codable, Identifiable {
    let id: UUID
    let accountId: UUID
    let symbol: String
    let exchange: String
    let side: OrderSide
    let orderType: OrderType
    let quantity: Double
    let limitPrice: Double?
    let stopPrice: Double?
    let duration: OrderDuration
    let status: OrderStatus
    let filledQuantity: Double?
    let filledAvgPrice: Double?
    let estimatedCost: Double?
    let commission: Double?
    let submittedAt: String?
    let filledAt: String?
}

// MARK: - Quote
struct Quote: Codable {
    let symbol: String
    let currentPrice: Double
    let change: Double
    let changePercent: Double
    let high: Double
    let low: Double
    let open: Double
    let previousClose: Double
    let volume: Int?
    let timestamp: Int?
}

// MARK: - Transaction
enum TransactionType: String, Codable {
    case BUY, SELL, DIVIDEND, DEPOSIT, WITHDRAWAL, FEE
    var icon: String {
        switch self {
        case .BUY: return "arrow.down.circle.fill"
        case .SELL: return "arrow.up.circle.fill"
        case .DIVIDEND: return "dollarsign.arrow.circlepath"
        case .DEPOSIT: return "plus.circle.fill"
        case .WITHDRAWAL: return "minus.circle.fill"
        case .FEE: return "exclamationmark.circle.fill"
        }
    }
}

struct Transaction: Codable, Identifiable {
    let id: UUID
    let accountId: UUID
    let type: TransactionType
    let symbol: String?
    let quantity: Double?
    let price: Double?
    let amount: Double
    let commission: Double?
    let description: String?
    let settledAt: String?
}

// MARK: - Portfolio
struct PortfolioOverview: Codable {
    let totalValue: Double
    let totalCashBalance: Double
    let totalHoldingsValue: Double
    let totalGainLoss: Double
    let totalGainLossPercent: Double
    let dayChange: Double
    let dayChangePercent: Double
    let accounts: [AccountSummary]
    let holdings: [Holding]
}

// MARK: - Watchlist
struct WatchlistResponse: Codable, Identifiable {
    let id: UUID
    let name: String
    let items: [WatchlistItemResponse]?
}

struct WatchlistItemResponse: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let exchange: String
}

// MARK: - Paginated Response
struct PageResponse<T: Codable>: Codable {
    let content: [T]
    let totalPages: Int
    let totalElements: Int
    let number: Int
    let size: Int
}

// MARK: - Banking
enum BankingAccountType: String, Codable, CaseIterable {
    case chequing, savings, creditLine

    var displayName: String {
        switch self {
        case .chequing: return "Chequing"
        case .savings: return "Savings"
        case .creditLine: return "Credit Line"
        }
    }

    var icon: String {
        switch self {
        case .chequing: return "banknote"
        case .savings: return "building.columns.fill"
        case .creditLine: return "creditcard"
        }
    }
}

struct BankingAccount: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: BankingAccountType
    let accountNumber: String
    let balance: Double
    var creditLimit: Double? = nil
    let institution: String
}

// MARK: - Portfolio Allocation
struct AllocationEntry: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let percentage: Double
    let holdings: [Holding]
}

enum SectorMapping {
    static let mapping: [String: String] = [
        "RY": "Financials", "TD": "Financials", "BNS": "Financials",
        "BMO": "Financials", "CM": "Financials", "MFC": "Financials",
        "ENB": "Energy", "SU": "Energy", "CNQ": "Energy", "TRP": "Energy",
        "CNR": "Industrials", "CP": "Industrials", "WCN": "Industrials",
        "SHOP": "Technology", "CSU": "Technology", "OTEX": "Technology",
        "T": "Telecommunications", "BCE": "Telecommunications", "RCI.B": "Telecommunications",
        "XEQT": "ETF - Equity", "XGRO": "ETF - Growth", "XBAL": "ETF - Balanced",
        "VFV": "ETF - US Equity", "ZAG": "ETF - Bonds", "XIC": "ETF - Canadian",
        "AAPL": "Technology", "MSFT": "Technology", "GOOGL": "Technology",
        "AMZN": "Consumer Discretionary", "TSLA": "Consumer Discretionary",
    ]

    static func sector(for symbol: String) -> String {
        mapping[symbol] ?? "Other"
    }
}

// MARK: - Auto-Invest
enum AutoInvestFrequency: String, Codable, CaseIterable {
    case weekly, monthly

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct AutoInvestRule: Identifiable, Codable {
    let id: UUID
    var fromAccountId: UUID
    var toAccountId: UUID
    var amount: Double
    var frequency: AutoInvestFrequency
    var symbol: String
    var isActive: Bool
    var createdAt: Date

    var nextExecutionDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let next = Calendar.current.date(
            byAdding: frequency == .weekly ? .weekOfYear : .month,
            value: 1, to: Date()
        ) ?? Date()
        return formatter.string(from: next)
    }
}
