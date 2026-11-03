# Ruling ids across the trees

[`ruling-ids.sh`](./ruling-ids.sh) lists every ruling id in the tree, one line each: the id, the
leaf that holds it and the first words of the ruling. It reads the product rulings under
`public/*/*/history/`, the constitution's rulings and its open bills, so a citation such as
`LINE3` or `DA7` is found without knowing which leaf it lives in.

```
bash public/scratch-tools/ruling-ids.sh           # every id
bash public/scratch-tools/ruling-ids.sh LINE      # ids starting LINE
```

It finds an id by the bold `**ID.**` opening a list item, the shape every rulings leaf and bill in
this tree uses; a ruling written any other way is skipped silently. Run it from the tree's root.
