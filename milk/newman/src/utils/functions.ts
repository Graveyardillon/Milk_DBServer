function parseBool(value: string | boolean): boolean | undefined {
    switch (value) {
    case 'true':
    case '1':
    case true:
        return true
    case 'false':
    case '0':
    case false:
        return false
    default:
        return undefined
    }
}

export {
    parseBool
}