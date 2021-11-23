const newman = require('newman')
const yargs = require('yargs/yargs')
import { NewmanJson, CreateEntrant, Item, ConfirmInvitation } from '../utils/interfaces'

const argv = yargs(process.argv.slice(2))
    .options({
        tournament_id: { type: 'number', default: 1}
    })
    .argv

function entrantItems(entrantCount: number): Item[] {
    let items: Item[] = []
    for (let i=2; i<entrantCount+2; i++) {
        const entrantJson: CreateEntrant = {
            entrant: {
                tournament_id: argv.tournament_id,
                user_id:       i
            }
        }

        items.push({
            name: 'Create Entrant',
            request: {
                url: 'http://localhost:4001/api/entrant',
                method: 'POST',
                header: [
                    {
                        key: 'Content-Type',
                        value: 'application/json'
                    }
                ],
                body: {
                    mode: 'raw',
                    raw: JSON.stringify(entrantJson)
                }
            }
        })
    }

    return items
}

const newmanJson: NewmanJson = {
    info: {
        name: 'Create Entrant Request',
    },
    item: entrantItems(4)
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