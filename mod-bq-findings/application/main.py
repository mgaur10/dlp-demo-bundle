# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


## NOTE: This provides PoC demo environment for various use cases ##
##  This is not built for production workload ##
## author@manishgaur

from __future__ import print_function

import argparse
import json
import os


PROJECT_ID = os.getenv('PROJ_ID')

PUB_SUB_TOPIC = os.getenv('PB_SB_TOP')
SUB_ID = os.getenv('SUB_ID')
MIN_LIKELIHOOD = os.getenv('MIN_LIKELIHOOD', 'POSSIBLE')
"""The minimum_likelihood (Enum) required before returning a match"""
"""For more info visit: https://cloud.google.com/dlp/docs/likelihood"""
MAX_FINDINGS = 0
"""The maximum number of findings to report (0 = server maximum)"""

INFO_TYPES = os.getenv('INFO_TYPES', 'FIRST_NAME,LAST_NAME,EMAIL_ADDRESS,US_SOCIAL_SECURITY_NUMBER,CREDIT_CARD_NUMBER,PHONE_NUMBER').split(',')
"""The infoTypes of information to match. ALL_BASIC for common infoTypes"""
"""For more info visit: https://cloud.google.com/dlp/docs/concepts-infotypes"""
DATASET_ID = os.getenv('DATASET_ID')
TABLE_ID = os.getenv('TABLE_ID')


def inspect_bigquery(data, context):

    project=PROJECT_ID
    bigquery_project=PROJECT_ID
    dataset_id=DATASET_ID
    table_id=TABLE_ID
    topic_id=PUB_SUB_TOPIC
    subscription_id=SUB_ID
    info_types=INFO_TYPES
    custom_dictionaries=None
    custom_regexes=None
    min_likelihood=MIN_LIKELIHOOD
    max_findings=MAX_FINDINGS
    timeout=300

    """Uses the Data Loss Prevention API to analyze BigQuery data.
    Args:
        project: The Google Cloud project id to use as a parent resource.
        bigquery_project: The Google Cloud project id of the target table.
        dataset_id: The id of the target BigQuery dataset.
        table_id: The id of the target BigQuery table.
        topic_id: The id of the Cloud Pub/Sub topic to which the API will
            broadcast job completion. The topic must already exist.
        subscription_id: The id of the Cloud Pub/Sub subscription to listen on
            while waiting for job completion. The subscription must already
            exist and be subscribed to the topic.
        info_types: A list of strings representing info types to look for.
            A full list of info type categories can be fetched from the API.
        namespace_id: The namespace of the Datastore document, if applicable.
        min_likelihood: A string representing the minimum likelihood threshold
            that constitutes a match. One of: 'LIKELIHOOD_UNSPECIFIED',
            'VERY_UNLIKELY', 'UNLIKELY', 'POSSIBLE', 'LIKELY', 'VERY_LIKELY'.
        max_findings: The maximum number of findings to report; 0 = no maximum.
        timeout: The number of seconds to wait for a response from the API.
    Returns:
        None; the response from the API is printed to the terminal.
    """

    # Import the client library.
    # This sample also uses threading.Event() to wait for the job to finish.
    import threading

    import google.cloud.dlp

    # This sample additionally uses Cloud Pub/Sub to receive results from
    # potentially long-running operations.
    import google.cloud.pubsub

    # Instantiate a client.
    dlp = google.cloud.dlp_v2.DlpServiceClient()

    # Prepare info_types by converting the list of strings into a list of
    # dictionaries (protos are also accepted).
    if not info_types:
        info_types = ["FIRST_NAME", "LAST_NAME", "EMAIL_ADDRESS"]
    info_types = [{"name": info_type} for info_type in info_types]


    # Prepare custom_info_types by parsing the dictionary word lists and
    # regex patterns.
    #if custom_dictionaries is None:
    #    custom_dictionaries = []
    #dictionaries = [
    #    {
    #        "info_type": {"name": "CUSTOM_DICTIONARY_{}".format(i)},
    #        "dictionary": {"word_list": {"words": custom_dict.split("Oscar P Schmidt,Thelma M Hogan,Jesse K Hopper")}},
    #    }
    #    for i, custom_dict in enumerate(custom_dictionaries)
    #]
    #if custom_regexes is None:
    #    custom_regexes = []
    #regexes = [
    #    {
    #        "info_type": {"Cust_reg_Pat": "CUSTOM_REGEX_{}".format(i)},
    #        "regex": {"pattern": custom_regex},
    #   }
    #    for i, custom_regex in enumerate(custom_regexes)
    #]
    #custom_info_types = dictionaries
    # + regexes

    # Construct the configuration dictionary. Keys which are None may
    # optionally be omitted entirely.
    inspect_config = {
        "info_types": info_types,
    #    "custom_info_types": custom_info_types,
        "min_likelihood": min_likelihood,
        "limits": {"max_findings_per_request": max_findings},
    }

    # Construct a storage_config containing the target Bigquery info.
    storage_config = {
        "big_query_options": {
            "table_reference": {
                "project_id": bigquery_project,
                "dataset_id": dataset_id,
                "table_id": table_id,
            }
        }
    }

    # Convert the project id into full resource ids.
    topic = google.cloud.pubsub.PublisherClient.topic_path(project, topic_id)
    parent = f"projects/{project}/locations/global"

    # Tell the API where to send a notification when the job is complete.
    actions = [
        {"pub_sub": {"topic": topic}},
        {
        'publish_summary_to_cscc': {

        }
      },{
    "publish_findings_to_cloud_data_catalog": {
       }
      }
    ]

    # Construct the inspect_job, which defines the entire inspect content task.
    inspect_job = {
        "inspect_config": inspect_config,
        "storage_config": storage_config,
        "actions": actions,
    }

    operation = dlp.create_dlp_job(
        request={"parent": parent, "inspect_job": inspect_job}
    )
    print("Inspection operation started: {}".format(operation.name))

    # Create a Pub/Sub client and find the subscription. The subscription is
    # expected to already be listening to the topic.
    subscriber = google.cloud.pubsub.SubscriberClient()
    subscription_path = subscriber.subscription_path(project, subscription_id)

    # Set up a callback to acknowledge a message. This closes around an event
    # so that it can signal that it is done and the main thread can continue.
    job_done = threading.Event()

    def callback(message):
        try:
            if message.attributes["DlpJobName"] == operation.name:
                # This is the message we're looking for, so acknowledge it.
                message.ack()

                # Now that the job is done, fetch the results and print them.
                job = dlp.get_dlp_job(request={"name": operation.name})
                if job.inspect_details.result.info_type_stats:
                    for finding in job.inspect_details.result.info_type_stats:
                        print(
                            "Info type: {}; Count: {}".format(
                                finding.info_type.name, finding.count
                            )
                        )
                else:
                    print("No findings.")

                # Signal to the main thread that we can exit.
                job_done.set()
            else:
                # This is not the message we're looking for.
                message.drop()
        except Exception as e:
            # Because this is executing in a thread, an exception won't be
            # noted unless we print it manually.
            print(e)
            raise

    # Register the callback and wait on the event.
    subscriber.subscribe(subscription_path, callback=callback)
    finished = job_done.wait(timeout=timeout)
    if not finished:
        print(
            "No event received before the timeout. Please verify that the "
            "subscription provided is subscribed to the topic provided."
        )


# [END dlp_inspect_bigquery]