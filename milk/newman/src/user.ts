const newman = require('newman')
const yargs = require('yargs')
import { NewmanJson, Signup } from './utils/interfaces'
import { Urls } from './utils/urls'

const argv = yargs(process.argv.slice(2))
    .options({
        email:    { type: 'string', default: 'default@mail.com' },
        password: { type: 'string', default: 'Password123'},
        name:     { type: 'string', default: 'default'}
    })
    .argv

const signupJson: Signup = {
    user: {
        email:    argv.email,
        password: argv.password,
        name:     argv.name,
    }
}

const newmanJson: NewmanJson = {
    info: {
        name: 'Signup request'
    },
    item: [
        {
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
        }
    ]
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