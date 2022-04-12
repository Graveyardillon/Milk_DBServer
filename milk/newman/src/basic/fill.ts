const newman = require('newman')
const yargs = require('yargs/yargs')
import { NewmanJson, CreateEntrant, Item } from '../utils/interfaces'

const argv = yargs(process.argv.slice(2))
    .options({
        tournament_id:     { type: 'number',  default: 1},
        master_as_entrant: { type: 'boolean', default: false }
    })
    .argv

function entrantItems(entrantCount: number): Item[] {
    let items: Item[] = []
    const initialValue = argv.master_as_entrant ? 1 : 2
    for (let i=initialValue; i<entrantCount+initialValue; i++) {
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
    item: entrantItems(9)
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