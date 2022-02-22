function device_list = get_docked_usb_devices()
%GET_DOCKED_USB_DEVICES  Returns struct array for docked usb devices

device_list = TMSiSAGA.DeviceLib.getDeviceList(...
    TMSiSAGA.TMSiUtils.toInterfaceTypeNumber('usb'), ...
    TMSiSAGA.TMSiUtils.toInterfaceTypeNumber('electrical'),...
    5,   ... % Allow 5 retries 
    2);      % Allow maximum of 2 devices to connect

end