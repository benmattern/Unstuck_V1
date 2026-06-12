import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://bllejypyuqjqybhlfnvf.supabase.co")!,
    supabaseKey: "sb_publishable_IFMHlmf3e53fST9i7dlHOA_H6A6dgrH",
    options: SupabaseClientOptions(
        auth: .init(emitLocalSessionAsInitialSession: true)
    )
)
