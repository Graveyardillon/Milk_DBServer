#!/bin/bash

newman run data_setup.json
newman run tournament8.json
newman run finished_tournament.json
newman run additional_data_setup.json
newman run notif.json