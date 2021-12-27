<?php
$SEND_TOKEN = null;
$CI_SLACK_WEBHOOK_URL = getenv("CI_SLACK_WEBHOOK_URL");
$CI_TEAMS_WEBHOOK_URL = getenv("CI_TEAMS_WEBHOOK_URL");

$LOG_FILE = './send.log';
define('LOG_FILE', $LOG_FILE);

$profile = null;
$profiles = array();
$_profiles = array(
    'webhook_url' => null,
    'teams_webhook_url' => null,
    'default_channel' => null,
    'from_name' => null,
    'members' => array()
);
require_once ('config.php');
foreach ($profiles as $key => $value) {
    $profiles[$key] = array_merge($_profiles, $value);
}
if (isset($_REQUEST['profile']) && is_numeric($_REQUEST['profile'])) {
    $profile = $profiles[$_REQUEST['profile']];
}
if (empty($profile)) {
    log_append('Invalid profile');
    die();
}
if (! empty($profile['webhook_url'])) {
    $CI_SLACK_WEBHOOK_URL = $profile['webhook_url'];
}
if (! empty($profile['teams_webhook_url'])) {
    $CI_TEAMS_WEBHOOK_URL = $profile['teams_webhook_url'];
}
if (empty($CI_SLACK_WEBHOOK_URL) && empty($CI_TEAMS_WEBHOOK_URL)) {
    log_append('Invalid Webhook URL');
    die();
}

$CI_MEMBERS = $profile['members'];
define('CI_SLACK_WEBHOOK_URL', $CI_SLACK_WEBHOOK_URL);
define('CI_TEAMS_WEBHOOK_URL', $CI_TEAMS_WEBHOOK_URL);
define('CI_MEMBERS', $CI_MEMBERS);

function pr($var)
{
    echo '<pre>';
    print_r($var);
    echo '</pre>';
}

function log_append($message, $time = null)
{
    $time = $time === null ? time() : $time;
    $date = date('Y-m-d H:i:s');
    $pre = $date . ' (' . $_SERVER['REMOTE_ADDR'] . '): ';
    file_put_contents(LOG_FILE, $pre . $message . "\n", FILE_APPEND);
}

function exec_command($command)
{
    $output = array();
    exec($command, $output);
    log_append('EXEC: ' . $command);
    foreach ($output as $line) {
        log_append('SHELL: ' . $line);
    }
}

function slack($message, $room = null, $username = null, $icon = ":bell:")
{
    if (! CI_SLACK_WEBHOOK_URL) {
        return false;
    }
    $attachments = array();
    if (is_array($message)) {
        $_message = '';
        $_attachments = array(
            'text' => '',
            'color' => ''
        );
        foreach ($message as $key => $value) {
            if (is_string($value)) {
                $_message = $value;
            } else {
                $value = array_merge($_attachments, $value);
                $attachments[] = array(
                    'text' => $value['text'],
                    'color' => $value['color']
                );
            }
        }
        $message = $_message;
    }
    $payload = array(
        "text" => $message,
        "icon_emoji" => $icon
    );
    if (! empty($attachments)) {
        $payload['attachments'] = $attachments;
    }
    if (! empty($room)) {
        $payload['channel'] = $room;
    }
    if (! empty($username)) {
        $payload['username'] = $username;
    }
    $data = "payload=" . json_encode($payload);
    $ch = curl_init(CI_SLACK_WEBHOOK_URL);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $result = curl_exec($ch);
    curl_close($ch);
    return $result;
}

function teams($message, $to_name = null, $to_email = null)
{
    if (! CI_TEAMS_WEBHOOK_URL) {
        return false;
    }
    if (is_null($to_name) || is_null($to_email)) {
        $jsonData = array('text' => $message);
    } else {
        $jsonData = array(
            "type" => "message",
            "attachments" => array(
                array(
                    "contentType" => "application/vnd.microsoft.card.adaptive",
                    "content" => array(
                        "\$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
                        "type" => "AdaptiveCard",
                        "version" => "1.0",
                        "body" => array(
                            array(
                                "type" => "TextBlock",
                                "size" => "Medium",
                                "weight" => "Bolder",
                                "text" => "Message To <at>" . $to_name . "</at>:",
                            ),
                            array(
                                "type" => "TextBlock",
                                "text" => $message,
                                "wrap" => true,
                            )
                        ),
                        "msteams" => array(
                            "entities" => array(
                                array(
                                    "type" => "mention",
                                    "text" => "<at>" . $to_name . "</at>",
                                    "mentioned" => array(
                                        "id" => $to_email,
                                        "name" => $to_name,
                                    )
                                )
                            )
                        )
                    )
                )
            )
        );
    }
    $jsonDataEncoded = json_encode($jsonData, true);
    $header = array();
    $header[] = 'Content-type: application/json';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, CI_TEAMS_WEBHOOK_URL);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $jsonDataEncoded);
    curl_setopt($ch, CURLOPT_HEADER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
    $result = curl_exec($ch);
    curl_close($ch);
    return $result;
}

function member($field, $search)
{
    $members = CI_MEMBERS;
    foreach ($members as $key => $value) {
        if (in_array($search, $value) && isset($value[$field])) {
            return $value[$field];
        }
    }
    return null;
}

function slack_user($search)
{
    $members = CI_MEMBERS;
    foreach ($members as $key => $value) {
        if (in_array($search, $value) && isset($value['slackid'])) {
            return '@' . $value['slackid'];
        }
    }
    return null;
}

if (isset($SEND_TOKEN)) {
    $request_token = isset($_REQUEST['token']) ? $_REQUEST['token'] : '';
    if (empty($request_token)) {
        log_append('Missing hook token');
        die();
    }
    if ($request_token !== $SEND_TOKEN) {
        log_append('Invalid hook token');
        die();
    }
}

$msg = "";
$to = $profile['default_channel'];
if (isset($_REQUEST['to_channel']) && ! empty($_REQUEST['to_channel'])) {
    $to = '#'.$_REQUEST['to_channel'];
}
if (isset($_REQUEST['to_user']) && ! empty($_REQUEST['to_user'])) {
    $slack_user = slack_user($_REQUEST['to_user']);
    if (! empty($slack_user)) {
        $to = $slack_user;
    }
}
if (isset($_REQUEST['text']) && ! empty($_REQUEST['text'])) {
    $msg = $_REQUEST['text'];
}

$res = slack($msg, $to, $profile['from_name']);
if ($res != 'ok') {
    log_append("${msg} - ${res}");
}
// TEAMS
$teams_to_name = null;
$teams_to_email = null;
if (isset($_REQUEST['to_user']) && ! empty($_REQUEST['to_user'])) {
    $teams_to_name = member('name', $_REQUEST['to_user']);
    $teams_to_email = member('teamsid', $_REQUEST['to_user']);
}
teams($msg);
