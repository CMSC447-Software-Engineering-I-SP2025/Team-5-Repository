import json

def filter_data(input_file: str, output_file: str):
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
        filtered = {key: item for (key, item) in data.items() if isinstance(item.get('imdb_id'), str)}
        with open(output_file, 'w', encoding='utf-8') as out:
            json.dump(filtered, out)

if __name__ == "__main__":
    filter_data("tmdb_dump_2025-04-10.json", "cleaned.json")
