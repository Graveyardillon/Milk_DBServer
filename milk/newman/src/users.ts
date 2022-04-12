const newman = require('newman')
const yargs = require('yargs')
import { NewmanJson, Signup, Item } from './utils/interfaces'
import { Urls } from './utils/urls'

const argv = yargs(process.argv.slice(2))
    .options({
        count:    { type: 'number', default: 20}
    })
    .argv

function userItems(n: number): Item[] {
    let items: Item[] = []
    for (let i=1; i<=n; i++) {
        const signupJson: Signup = {
            user: {
                email:    `test${i}user@gmail.com`,
                password: 'Password123',
                name:     `test${i}user`,
            }
        }

        items.push({
            name: 'Signup',
            request: {
                url: Urls.signup,
                method: 'POST',
                header: [
                    {
                        key: 'Content-Type',
                        value: 'application/json'
                    }
                ],
                body: {
                    mode: 'raw',
                    raw: JSON.stringify(signupJson)
                }
            }
        })
    }

    return items
}

const newmanJson: NewmanJson = {
    info: {
        name: 'Signup request'
    },
    item: userItems(argv.count)
}

newman.run({
    collection: newmanJson,
    reporters: 'cli'
}, (err: any, summary: any) => {
    if (err) throw err

    summary.run.executions.forEach((exec: any) => {
        console.log('Request name:', exec.item.name)
        console.log('Response:', JSON.parse(exec.response.stream))
    })
})