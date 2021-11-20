interface NewmanJson {
    info: {
        name: string
    },
    item: Item[]
}

interface Item {
    name: string,
    request: {
        url:    string,
        method: string,
        header: Header[]
        body:   Body
    }
}

interface Header {
    key:   string
    value: string
}

interface Body {
    mode:      string
    formdata?: FormData[]
    raw?:      string
}

interface FormData {
    key:     string
    type:    string
    enabled: boolean
    src?:    string
    value?:  string
}

interface CreateTournament {
    assistants?:            number[]
    capacity:               number
    coin_head_field?:       string
    coin_tail_field?:       string
    deadline:               string
    description:            string
    discord_server_id?:     string
    enabled_discord_server: boolean
    enabled_coin_toss:      boolean
    enabled_map:            boolean
    event_date:             string
    game_id:                number
    game_name:              string
    is_team:                boolean
    join:                   false
    map_rule?:              string
    maps?:                  Map[]
    master_id:              number
    name:                   string
    password?:              string
    platform_id:            number
    rule:                   string
    start_recruiting:       string
    team_size?:             number
    thumbnail_image?:       string
    type:                   number
    url?:                   string
}

interface Map {
    icon_path?: string
    icon?: string
    name: string
}

export {
    NewmanJson,
    CreateTournament
}