package com.rmb.wf_app_android;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;

/**
 * Created by rmb on 28/03/16.
 */
public final class WebService {

    public String validateUser (String qrcode) {

        String json = new String();

        try {
            URL url = new URL("http://Ruis-MBP.lan:3000/validateUser/" + qrcode);
            BufferedReader br = new BufferedReader(new InputStreamReader(url.openStream()));
            String tmp = new String();

            while ((tmp = br.readLine()) != null) {
                json.concat(tmp);
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return json;
    }


    public String setTime (String qrcode) {

        String json = new String();

        try {
            URL url = new URL("http://Ruis-MBP.lan:3000/setTime/" + qrcode);
            BufferedReader br = new BufferedReader(new InputStreamReader(url.openStream()));
            String tmp = new String();

            while ((tmp = br.readLine()) != null) {
                json.concat(tmp);
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return json;
    }


}
