import Slingshot

extension Character {
    static var uppercaseAlphabet: [Character] {
        (65...90)
            .map(compose(UnicodeScalar.init, Character.init))
    }
}
