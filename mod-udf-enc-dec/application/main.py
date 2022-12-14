import json
import base64
import os
# Import the client library
import google.cloud.dlp
# from google.cloud.storage import Client
from google.cloud import storage
import google.auth
# Instantiate a client
dlp = google.cloud.dlp_v2.DlpServiceClient()

PROJECT_ID = os.getenv('PROJECT_ID')
BUCKET_NAME = os.getenv('BUCKET_NAME')
BLOB_NAME = os.getenv('BLOB_NAME')
KEY_NAME = os.getenv('KEY_NAME')


"""Re-identifies content that was previously de-identified through deterministic encryption.
Args:
    project: The Google Cloud project ID to use as a parent resource.
    input_str: The string to be re-identified. Provide the entire token. Example:
        EMAIL_ADDRESS_TOKEN(52):AVAx2eIEnIQP5jbNEr2j9wLOAd5m4kpSBR/0jjjGdAOmryzZbE/q
    surrogate_type: The name of the surrogate custom infoType used
        during the encryption process.
    key_name: The name of the Cloud KMS key used to encrypt ("wrap") the
        AES-256 key. Example:
        keyName = 'projects/YOUR_GCLOUD_PROJECT/locations/YOUR_LOCATION/
        keyRings/YOUR_KEYRING_NAME/cryptoKeys/YOUR_KEY_NAME'
    wrapped_key: The encrypted ("wrapped") AES-256 key previously used to encrypt the content.
        This key must have been encrypted using the Cloud KMS key specified by key_name.
Returns:
    None; the response from the API is printed to the terminal.
"""
def remote_security(request):
   request_json = request.get_json()
   mode = request_json['userDefinedContext']['mode']
   calls = request_json['calls']
   if mode == "deidentify":
       return deidentify(calls)
   elif mode == "deidentify_cc":
       return deidentify_cc(calls)
   elif mode == "reidentify":
       return reidentify(calls)
   return json.dumps({"Error in Request": request_json}), 400

def reidentify(
    calls
):

    # Convert the project id into a full resource id.
    credentials, project_id = google.auth.default()
    parent = f"projects/{project_id}"
    return_value = []
    surrogate_type ="SSN"
    bucket_name = BUCKET_NAME
    blob_name = BLOB_NAME
    # The wrapped key is base64-encoded, but the library expects a binary
    # string, so decode it here.
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)

    wrapped_key = blob.download_as_text(encoding="utf-8")
    wrapped_key = base64.b64decode(wrapped_key)
    key_name = KEY_NAME
    # "projects/{project_id}/locations/global/keyRings/dlp_key_ring/cryptoKeys/udf_key"
    
    # Construct reidentify Configuration
    reidentify_config = {
        "info_type_transformations": {
            "transformations": [
                {
                    "primitive_transformation": {
                        "crypto_deterministic_config": {
                            "crypto_key": {
                                "kms_wrapped": {
                                    "wrapped_key": wrapped_key,
                                    "crypto_key_name": key_name,
                                }
                            },
                            "surrogate_info_type": {"name": surrogate_type},
                        }
                    }
                }
            ]
        }
    }

    inspect_config = {
        "custom_info_types": [
            {"info_type": {"name": surrogate_type}, "surrogate_type": {}}
        ]
    }
    for input_str in calls:

        # Convert string to item
        item = {"value": input_str[0]}
        # Call the API
        response = dlp.reidentify_content(
            request={
                "parent": parent,
                "reidentify_config": reidentify_config,
                "inspect_config": inspect_config,
                "item": item,
            }
        )
        return_value.append(str(response.item.value))
    return json.dumps({"replies": return_value})


def deidentify(
    calls,
):
    dlp = google.cloud.dlp_v2.DlpServiceClient()
        
    credentials, project_id = google.auth.default()
    parent = f"projects/{project_id}"
    return_value = []
    surrogate_type ="SSN"
    info_types = ["US_SOCIAL_SECURITY_NUMBER"]
    bucket_name = BUCKET_NAME
    blob_name = BLOB_NAME
    # The wrapped key is base64-encoded, but the library expects a binary
    # string, so decode it here.
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)

    wrapped_key = blob.download_as_text(encoding="utf-8")
    wrapped_key = base64.b64decode(wrapped_key)
    key_name = KEY_NAME
    # "projects/{project_id}/locations/global/keyRings/dlp_key_ring/cryptoKeys/udf_key"

    # Construct Deterministic encryption configuration dictionary
    crypto_replace_deterministic_config = {
        "crypto_key": {
            "kms_wrapped": {"wrapped_key": wrapped_key, "crypto_key_name": key_name}
        },
    }

    # Add surrogate type
    if surrogate_type:
        crypto_replace_deterministic_config["surrogate_info_type"] = {
            "name": surrogate_type
        }

    # Construct inspect configuration dictionary
    inspect_config = {"info_types": [{"name": info_type} for info_type in info_types]}

    # Construct deidentify configuration dictionary
    deidentify_config = {
        "info_type_transformations": {
            "transformations": [
                {
                    "primitive_transformation": {
                        "crypto_deterministic_config": crypto_replace_deterministic_config
                    }
                }
            ]
        }
    }

    for input_str in calls:
        # Convert string to item
        item = {"value": input_str[0]}
        # Call the API
        response = dlp.deidentify_content(
            request={
                "parent": parent,
                "deidentify_config": deidentify_config,
                "inspect_config": inspect_config,
                "item": item,
            }
        )
        return_value.append(str(response.item.value))
    return json.dumps({"replies": return_value})



def deidentify_cc(
    calls,
):
    dlp = google.cloud.dlp_v2.DlpServiceClient()
        
    credentials, project_id = google.auth.default()
    parent = f"projects/{project_id}"
    return_value = []
    number_to_mask = 0
    masking_character=None
    info_types = ["CREDIT_CARD_NUMBER"]

    # Construct inspect configuration dictionary
    inspect_config = {"info_types": [{"name": info_type} for info_type in info_types]}

    # Construct deidentify configuration dictionary
    deidentify_config = {
        "info_type_transformations": {
            "transformations": [
                {
                    "primitive_transformation": {
                        "character_mask_config": {
                            "masking_character": masking_character,
                            "number_to_mask": number_to_mask,
                        }
                    }
                }
            ]
        }
    }

    for input_str in calls:
        # Convert string to item
        item = {"value": input_str[0]}
        # Call the API
        response = dlp.deidentify_content(
            request={
                "parent": parent,
                "deidentify_config": deidentify_config,
                "inspect_config": inspect_config,
                "item": item,
            }
        )
        return_value.append(str(response.item.value))
    return json.dumps({"replies": return_value})
