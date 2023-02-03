import re


if __name__ == "__main__":
    with open("template/export.json", "r") as src:
        data = src.read()

        # Find all UUID
        UUIDS = re.findall(
            r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", data
        )
        print(f"Found {len(UUIDS)} UUIDs")

        # Replace all UUID with "{{UUID_XXX}}"
        for i, uuid in enumerate(UUIDS):
            data = data.replace(uuid, f"{{{{UUID_{i + 1}}}}}")

        # Write to file
        with open("template/new.json", "w") as dst:
            dst.write(data)

        print("Done")
