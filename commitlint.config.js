module.exports = {
    extends: ["@commitlint/config-conventional"],
    rules: {
        "body-max-line-length": [1, "always", 100],
        "subject-case": [1, "always", "lower-case"],
        "subject-empty": [1, "never"],
        "type-empty": [1, "never"],
    },
}
