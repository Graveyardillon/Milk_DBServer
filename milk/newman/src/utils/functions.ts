function parseBool(value: string): boolean | undefined {
    switch (value) {
    case 'true':
    case '1':
        return true
    case 'false':
    case '0':
        return false
    default:
        return undefined
    }
}

export {
    parseBool
}