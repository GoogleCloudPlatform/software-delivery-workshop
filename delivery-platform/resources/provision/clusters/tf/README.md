

Create the foundation
- Requires `base_image` and `foundation` to be created first

```
gcloud builds submit
```

Destroy the  foundation

```
gcloud builds submit --config cloudbuild-destroy.yaml
```