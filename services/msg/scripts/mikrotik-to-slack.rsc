:global lastTime
:global messageencoded ""
:global output

:local currentBuf [ :toarray [ /log find topics~"critical" || message~"LTSlack" || message~"[Ff]ailure" || message~"[Ff]ailed" || message~"disabled" && message~"^[^fetch]" ] ];
:local currentLineCount [ :len $currentBuf ];

if ($currentLineCount > 0) do={
   :local currentTime "$[ /log get [ :pick $currentBuf ($currentLineCount -1) ] time ]";

   :if ([:len $currentTime] = 15 ) do={
      :set currentTime [ :pick $currentTime 7 15 ];
   }

   :set output "$currentTime - $[/log get [ :pick $currentBuf ($currentLineCount-1) ] message ]";

   :for i from=0 to=([:len $output] - 1) do={
      :local char [:pick $output $i]
      :if ($char = " ") do={
         :set $char "%20"
      }
      :if ($char = "-") do={
         :set $char "%2D"
      }
      :if ($char = "#") do={
         :set $char "%23"
      }
      :if ($char = "+") do={
         :set $char "%2B"
      }
      :if ($char = ",") do={
         :set $char "%2C"
      }
      :if ($char = ">") do={
         :set $char "%3E"
      }
      :if ($char = ":") do={
         :set $char "%3A"
      }
      :set messageencoded ($messageencoded . $char)
   }

   :if (([:len $lastTime] < 1) || (([:len $lastTime] > 0) && ($lastTime != $currentTime))) do={
      :set lastTime $currentTime ;
      /tool fetch mode=http url="http://{{ DK_MSG_HOST }}:8002/send.php?profile=1&to_channel=mikrotik" http-method=post http-data="text=$messageencoded";
      /log info "LogToSlack sent";
   }
}
