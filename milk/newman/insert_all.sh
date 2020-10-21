#!/bin/bash

newman run data_setup.json
newman run additional_data_setup.json
