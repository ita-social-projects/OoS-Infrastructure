locals {
    # get_env("GOOGLE_APPLICATION_CREDENTIALS")
    google_env_var = get_env("GOOGLE_APPLICATION_CREDENTIALS", "")

    # get file path, second value is fallback parameter
    # command gcloud auth application-default login will save application_default_credentials.json
    home_dir = get_env("HOME")
    credentials = find_in_parent_folders("${local.home_dir}/.config/gcloud/application_default_credentials.json")

}

terraform {
    extra_arguments "core_vars" {
        commands = get_terraform_commands_that_need_vars()

        arguments = [
            "-var-file=./gcp.tfvars"
        ]
    }
}

inputs = {
    credentials = local.google_env_var == "" ? local.credentials : local.google_env_var
}
