<?php
$CI_GITLAB_WEBHOOK_TOKEN = getenv("CI_GITLAB_WEBHOOK_TOKEN");
$CI_SLACK_WEBHOOK_URL = getenv("CI_SLACK_WEBHOOK_URL");

$LOG_FILE = './gitlab_webhook.log';
define('LOG_FILE', $LOG_FILE);

$profile = null;
$profiles = array();
$_profiles = array(
    'webhook_url' => null,
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

if (empty($CI_SLACK_WEBHOOK_URL)) {
    log_append('Invalid Slack Webhook URL');
    die();
}

$CI_SLACK_MEMBERS = $profile['members'];
define('CI_SLACK_WEBHOOK_URL', $CI_SLACK_WEBHOOK_URL);
define('CI_SLACK_MEMBERS', $CI_SLACK_MEMBERS);

function pr($var)
{
    echo '<pre>';
    print_r($var);
    echo '</pre>';
}

function convert_name2user($name)
{
    $f = array('À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'Ý', 'ß', 'à', 'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'ÿ', 'Ā', 'ā', 'Ă', 'ă', 'Ą', 'ą', 'Ć', 'ć', 'Ĉ', 'ĉ', 'Ċ', 'ċ', 'Č', 'č', 'Ď', 'ď', 'Đ', 'đ', 'Ē', 'ē', 'Ĕ', 'ĕ', 'Ė', 'ė', 'Ę', 'ę', 'Ě', 'ě', 'Ĝ', 'ĝ', 'Ğ', 'ğ', 'Ġ', 'ġ', 'Ģ', 'ģ', 'Ĥ', 'ĥ', 'Ħ', 'ħ', 'Ĩ', 'ĩ', 'Ī', 'ī', 'Ĭ', 'ĭ', 'Į', 'į', 'İ', 'ı', 'Ĳ', 'ĳ', 'Ĵ', 'ĵ', 'Ķ', 'ķ', 'Ĺ', 'ĺ', 'Ļ', 'ļ', 'Ľ', 'ľ', 'Ŀ', 'ŀ', 'Ł', 'ł', 'Ń', 'ń', 'Ņ', 'ņ', 'Ň', 'ň', 'ŉ', 'Ō', 'ō', 'Ŏ', 'ŏ', 'Ő', 'ő', 'Œ', 'œ', 'Ŕ', 'ŕ', 'Ŗ', 'ŗ', 'Ř', 'ř', 'Ś', 'ś', 'Ŝ', 'ŝ', 'Ş', 'ş', 'Š', 'š', 'Ţ', 'ţ', 'Ť', 'ť', 'Ŧ', 'ŧ', 'Ũ', 'ũ', 'Ū', 'ū', 'Ŭ', 'ŭ', 'Ů', 'ů', 'Ű', 'ű', 'Ų', 'ų', 'Ŵ', 'ŵ', 'Ŷ', 'ŷ', 'Ÿ', 'Ź', 'ź', 'Ż', 'ż', 'Ž', 'ž', 'ſ', 'ƒ', 'Ơ', 'ơ', 'Ư', 'ư', 'Ǎ', 'ǎ', 'Ǐ', 'ǐ', 'Ǒ', 'ǒ', 'Ǔ', 'ǔ', 'Ǖ', 'ǖ', 'Ǘ', 'ǘ', 'Ǚ', 'ǚ', 'Ǜ', 'ǜ', 'Ǻ', 'ǻ', 'Ǽ', 'ǽ', 'Ǿ', 'ǿ', 'º','ª','°');
    $t = array('A', 'A', 'A', 'A', 'A', 'A', 'AE', 'C', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'D', 'N', 'O', 'O', 'O', 'O', 'O', 'O', 'U', 'U', 'U', 'U', 'Y', 's', 'a', 'a', 'a', 'a', 'a', 'a', 'ae', 'c', 'e', 'e', 'e', 'e', 'i', 'i', 'i', 'i', 'n', 'o', 'o', 'o', 'o', 'o', 'o', 'u', 'u', 'u', 'u', 'y', 'y', 'A', 'a', 'A', 'a', 'A', 'a', 'C', 'c', 'C', 'c', 'C', 'c', 'C', 'c', 'D', 'd', 'D', 'd', 'E', 'e', 'E', 'e', 'E', 'e', 'E', 'e', 'E', 'e', 'G', 'g', 'G', 'g', 'G', 'g', 'G', 'g', 'H', 'h', 'H', 'h', 'I', 'i', 'I', 'i', 'I', 'i', 'I', 'i', 'I', 'i', 'IJ', 'ij', 'J', 'j', 'K', 'k', 'L', 'l', 'L', 'l', 'L', 'l', 'L', 'l', 'l', 'l', 'N', 'n', 'N', 'n', 'N', 'n', 'n', 'O', 'o', 'O', 'o', 'O', 'o', 'OE', 'oe', 'R', 'r', 'R', 'r', 'R', 'r', 'S', 's', 'S', 's', 'S', 's', 'S', 's', 'T', 't', 'T', 't', 'T', 't', 'U', 'u', 'U', 'u', 'U', 'u', 'U', 'u', 'U', 'u', 'U', 'u', 'W', 'w', 'Y', 'y', 'Y', 'Z', 'z', 'Z', 'z', 'Z', 'z', 's', 'f', 'O', 'o', 'U', 'u', 'A', 'a', 'I', 'i', 'O', 'o', 'U', 'u', 'U', 'u', 'U', 'u', 'U', 'u', 'U', 'u', 'A', 'a', 'AE', 'ae', 'O', 'o', ' ','a','o');
    $_name = str_replace($f, $t, $name);
    $_name = strtolower($_name);
    $_name = explode(' ', $_name);
    return implode('.', $_name);
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
    // curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $result = curl_exec($ch);
    curl_close($ch);
    return $result;
}

function slack_user($search)
{
    $members = CI_SLACK_MEMBERS;
    foreach ($members as $key => $value) {
        if (in_array($search, $value)) {
            return '@' . $key;
        }
    }
    return null;
}

if (isset($CI_GITLAB_WEBHOOK_TOKEN)) {
    $request_token = isset($_SERVER['HTTP_X_GITLAB_TOKEN']) ? $_SERVER['HTTP_X_GITLAB_TOKEN'] : '';
    if (empty($request_token)) {
        log_append('Missing hook token');
        die();
    }
    if ($request_token !== $CI_GITLAB_WEBHOOK_TOKEN) {
        log_append('Invalid hook token');
        die();
    }
}

$input = file_get_contents("php://input");

// log_append('..........................................');
// log_append($input);
// log_append('..........................................');

$json = json_decode($input, true);

if (! is_array($json)) {
    log_append('Empty data');
    die();
}

if (! isset($json['object_kind'])) {
    log_append('Invalid hook obj');
    die();
}

$channel_to = $profile['default_channel'];

switch ($json['object_kind']) {
    case 'merge_request':
        switch ($json['object_attributes']['action']) {
            case 'open':
                $slack_name = '';
                if (isset($json['assignee']['name'])) {
                    $slack_name = $json['assignee']['name'];
                }
                $slack_user = slack_user($json['assignee']['username']);
                if (! empty($slack_user)) {
                    $channel_to = $slack_user;
                } elseif (! empty($slack_name)) {
                    $slack_user = convert_name2user($slack_name);
                    if (! empty($slack_user)) {
                        $slack_user = "@{$slack_user}";
                        $channel_to = $slack_user;
                    }
                }
                $msg = "<{$json['project']['web_url']}|{$json['project']['path_with_namespace']}> - *{$json['user']['name']}* solicitou Merge Request <{$json['object_attributes']['url']}|#{$json['object_attributes']['iid']}> para *{$slack_name}* ({$slack_user}) - Branches *{$json['object_attributes']['source_branch']}* para *{$json['object_attributes']['target_branch']} em {$json['object_attributes']['created_at']}*";
                $res = slack($msg, $channel_to, $profile['from_name']);
                if ($res != 'ok') {
                    log_append("${msg} - ${res}");
                }
                break;
            case 'merge':
                $slack_name = '';
                if (isset($json['object_attributes']['last_commit']['author']['name'])) {
                    $slack_name = $json['object_attributes']['last_commit']['author']['name'];
                }
                $slack_user = slack_user($json['object_attributes']['last_commit']['author']['email']);
                if (! empty($slack_user)) {
                    $channel_to = $slack_user;
                } elseif (! empty($slack_name)) {
                    $slack_user = convert_name2user($slack_name);
                    if (! empty($slack_user)) {
                        $slack_user = "@{$slack_user}";
                        $channel_to = $slack_user;
                    }
                }
                $msg = "<{$json['project']['web_url']}|{$json['project']['path_with_namespace']}> - *{$json['user']['name']}* aceitou o Merge Request <{$json['object_attributes']['url']}|#{$json['object_attributes']['iid']}> (*{$json['object_attributes']['state']}*) aberto por *{$slack_name}* ({$slack_user}) - Branches *{$json['object_attributes']['source_branch']}* para *{$json['object_attributes']['target_branch']} em {$json['object_attributes']['created_at']}*";
                $res = slack($msg, $channel_to, $profile['from_name']);
                if ($res != 'ok') {
                    log_append("${msg} - ${res}");
                }
                break;
            default:
                log_append($json['object_attributes']['action'] . ' action not implemented');
        }
        break;
    case 'note':
        switch ($json['object_attributes']['noteable_type']) {
            case 'MergeRequest':
                $slack_name = '';
                if (isset($json['merge_request']['last_commit']['author']['name'])) {
                    $slack_name = $json['merge_request']['last_commit']['author']['name'];
                }
                $slack_user = slack_user($json['merge_request']['last_commit']['author']['email']);
                if (! empty($slack_user)) {
                    $channel_to = $slack_user;
                } elseif (! empty($slack_name)) {
                    $slack_user = convert_name2user($slack_name);
                    if (! empty($slack_user)) {
                        $slack_user = "@{$slack_user}";
                        $channel_to = $slack_user;
                    }
                }
                $msg = "<{$json['project']['web_url']}|{$json['project']['path_with_namespace']}> - *{$json['user']['name']}* fez um comentário no Merge Request <{$json['merge_request']['url']}|#{$json['merge_request']['iid']}> (*{$json['merge_request']['state']}*) - Branches *{$json['merge_request']['source_branch']}* para *{$json['merge_request']['target_branch']} em {$json['object_attributes']['created_at']}*";
                $res = slack($msg, $channel_to, $profile['from_name']);
                if ($res != 'ok') {
                    log_append("${msg} - ${res}");
                }
                break;
            default:
                log_append($json['object_attributes']['noteable_type'] . ' noteable_type not implemented');
        }
        break;
    case 'pipeline':
        switch ($json['object_attributes']['status']) {
            case 'pending':
                if ($json['object_attributes']['ref'] == $json['project']['default_branch']) {
                    $msg = "<{$json['project']['web_url']}|{$json['project']['path_with_namespace']}> - *{$json['user']['name']}* iniciou o Pipeline <{$json['project']['web_url']}/pipelines/{$json['object_attributes']['id']}|#{$json['object_attributes']['id']}> - Branch *{$json['object_attributes']['ref']}* em *{$json['object_attributes']['created_at']}*";
                    $res = slack($msg, $channel_to, $profile['from_name']);
                    if ($res != 'ok') {
                        log_append("${msg} - ${res}");
                    }
                }
                break;
            case 'success':
            case 'canceled':
            case 'failed':
                if ($json['object_attributes']['ref'] == $json['project']['default_branch']) {} else {
                    $channel_to = null;
                    $slack_name = '';
                    if (isset($json['user']['name'])) {
                        $slack_name = $json['user']['name'];
                    }
                    $slack_user = slack_user($json['user']['username']);
                    if (! empty($slack_user)) {
                        $channel_to = $slack_user;
                    } elseif (! empty($slack_name)) {
                        $slack_user = convert_name2user($slack_name);
                        if (! empty($slack_user)) {
                            $slack_user = "@{$slack_user}";
                            $channel_to = $slack_user;
                        }
                    }
                }
                if (! empty($channel_to)) {
                    $msg = array(
                        "<{$json['project']['web_url']}|{$json['project']['path_with_namespace']}> - O Pipeline <{$json['project']['web_url']}/pipelines/{$json['object_attributes']['id']}|#{$json['object_attributes']['id']}> finalizou - Branch *{$json['object_attributes']['ref']}* em *{$json['object_attributes']['finished_at']}*"
                    );
                    $msg[] = array(
                        'text' => "Status *{$json['object_attributes']['status']}* em *{$json['object_attributes']['duration']}s*",
                        'color' => ($json['object_attributes']['status'] == 'success') ? '#36a64f' : '#ff0000'
                    );
                    $res = slack($msg, $channel_to, $profile['from_name']);
                    if ($res != 'ok') {
                        log_append("${msg} - ${res}");
                    }
                }
                break;
        }
        break;
    default:
        log_append($json['object_kind'] . ' object_kind not implemented');
}

// log_append('Launching shell hook script...');
// exec_command('sh ' . $hookfile);
// log_append('Shell hook script finished');
