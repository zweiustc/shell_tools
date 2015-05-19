<?php
/*
** Zabbix
** Copyright (C) 2001-2014 Kingsoft cloud
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
**/


/**
 * Class containing methods for operations with KSC.
 *
 * @package API
 */
class CKSC extends CZBXAPI {
	/**
	 * Create KSC account for frontend.
	 *
	 * @param array $options
	 * @param array $options['accountname']
	 *
	 * @return array
	 */
	public function RegisterAccount($options = array()) {
		$accountname = $options['accountname'];
		$hostgroup = self::GetHostGroup($accountname);
		$usergroup = self::GetUserGroup($accountname);
		# create hostgroup
		$hostgroup_ret = API::HostGroup()->create(array('name' => $hostgroup));
		# create usergroup
		$usergroup_ret = API::UserGroup()->create(
					array(
						'name' => $usergroup,
						'rights' => array(
						array('permission' => 3, #read and write
							'id' => $hostgroup_ret['groupids'][0]),
						),));
		return array('Message' => 'Register account successfully');
	}

	/**
	 * Delete KSC account for frontend.
	 *
	 * @param array $options
	 * @param array $options['accountname']
	 *
	 * @return array
	 */
	public function DeleteAccount($options = array()) {
		$accountname = $options['accountname'];
		$hostgroup = self::GetHostGroup($accountname);
		$usergroup = self::GetUserGroup($accountname);

		#delete hostgroup
		$hgroup['output'] = 'groupid';
		$hgroup['filter'] = array('name' => array($hostgroup));
		$hgroup_ret = API::HostGroup()->get($hgroup);
		$groupids = array($hgroup_ret[0]['groupid']);
		$hgroup_ret = API::HostGroup()->delete($groupids);

		# delete usergroup
		$usrgrp['output'] = 'usrgrpid';
		$usrgrp['filter'] = array('name' => $usergroup);
		$usrgrp_ret = API::UserGroup()->get($usrgrp);
		$usrgrpids = array($usrgrp_ret[0]['usrgrpid']);
		$usrgrp_ret = API::UserGroup()->delete($usrgrpids);

		return array('Message' => 'Delete account successfully!');
	}

	/**
	* Create monitored-host for frontend.
	*
	* @param array $hosts
	* @param string $hosts['accountname']
	* @param string $hosts['hostname']
	* @param string $hosts['ip']
	* @param string|array $hosts['templates']
	*
	* @return array
	*/
	public function CreateHost($hosts) {
		$hosts = zbx_toArray($hosts);
		if (empty($hosts)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Empty input parameter.'));
		}
		$counter = count($hosts);
		$options = array();
		for ($i = 0; $i < $counter; $i++) {
		$host = $hosts[$i];
		$hostname = $host['hostname'];
		$hostip = $host['ip'];
		$templates = $host['templates'];
		$accountname = $host['accountname'];
		$hostgroup = self::GetHostGroup($accountname);
		if (empty($hostname) || empty($hostip) || empty($templates) || empty($hostgroup)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Incomplete input parameter.'));
		}
		$options[$i] = array(
			'host' => $hostname,
			'ip' => $hostip,
			'templates' => $templates,
			'groups' => $hostgroup
		);
		}
		$result = API::Host()->addHostsToProxy($options);
		return array('Message' => 'Create Host Successfully!');
	}

	/**
	* Delete monitored-host for frontend.
	*
	* @param string|array $hosts
	* @param string $hosts['hostname']
	*
	* @return array
	*/
	public function DeleteHost($hosts) {
		$hosts = zbx_toArray($hosts);
		if (empty($hosts)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Empty input parameter.'));
		}
		$counter = count($hosts);
		$options = array();
		for($i = 0; $i < $counter; $i++) {
			$host = $hosts[$i];
			if (empty($host['hostname'])) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Empty Hostname Existed.'));
			}
			$options[$i]['host'] = $host['hostname'];
		}
		$result = API::Host()->deleteByHostName($options);
		return array('Message' => 'Delete Host Successfully!');
	}

	/**
	* Delete all medias of one alter user
	*
	* @throw APIException if fail to delete all medias
	*
	* @param string username
	*
	* @return array
	*/
	protected function DeleteAlterUserAllMedias($username) {
		if (empty($username)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter'));
		}
		$userid = API::User()->get(array(
			'output' => 'userid',
			'filter' => array("alias" => $username)
			));
		$mediaIds_arr = API::UserMedia()->get(array(
			'output' => "extend",
			'userids' => $userid[0],
			));

		$mediaIds = array();
		$i = 0;
		foreach ($mediaIds_arr as $mediaId) {
			$mediaIds[$i] = $mediaId['mediaid'];
			$i++;
		}
		$action_ret = API::User()->deleteMedia($mediaIds);

		return array('Message' => 'Delete alter user media successfully');
	}

	/**
	* Update alter user medias
	*
	* @throws APIException if User media update is fail
	*
	* @param string $data['username']
	* @param string $data['accountname']
	* @param array $data['medias']
	* @param string $data['medias']['mediatype']
	* @param string $data['medias']['address']
	*
	* @return array
	*/
	public function UpdateAlterUserMedia($data = array()) {
		$accountname = $data['accountname'];
		$name = $data['username'];
		$username = self::TranslateAlterUserName($accountname, $name);
		if (empty($username)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter'));
		}
		$userid = API::User()->get(array(
			'output' => 'userid',
			'filter' => array("alias" => $username)
			));
		if (empty($userid)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: Do not have the user %s', $name));
		}
		$users = $userid;
		$i = 0;
		$severity = 63;
		$active = 0;
		$period = "1-7,00:00-24:00";
		$medias = array();
		$media = zbx_toArray($data['medias']);
		/*when the medias is empty, delete all the user's medias*/
		if (empty($media)) {
			self::DeleteAlterUserAllMedias($username);
			return array('Message' => 'Delete all user medias successfully');
		}
		/* update user's media*/
		foreach ($media as $mediaItem) {
			$mediaItem['mediatype'] = trim($mediaItem['mediatype']);
			$mediaItem['address'] = trim($mediaItem['address']);
			if ((!empty($mediaItem['mediatype'])) && (!empty($mediaItem['address']))) {
				$mediatypeid = API::MediaType()->get(array(
					'output' => 'mediatypeid',
					'filter' => array("description" => $mediaItem['mediatype'])
					));
				if (empty($mediatypeid)) {
					self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: unknown media type %s', $mediaItem['mediatype']));
				}
				$medias[$i]['mediatypeid'] = $mediatypeid[0]['mediatypeid'];
				$medias[$i]['sendto'] = $mediaItem['address'];
				$medias[$i]['severity'] = $severity;
				$medias[$i]['active'] = $active;
				$medias[$i]['period'] = $period;
				$i++;
			} else {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: mediatype or media address is empty'));
			}
		}
		$updatemedias['users'] = $users;
		$updatemedias['medias'] = $medias;
		$action_ret = API::User()->updateMedia($updatemedias);
		return array('Message' => 'Updata user media successfully');
	}

	/** Delete the medias with one type from user
	 *
	 * @throws APIException if fail to delete medias of one type
	 *
	 * @param string $data['userid']
	 * @param string $data['mediatypeid']
	 *
	 * @return array
	 */
	protected function DeleteOneTypeMedia($data) {
		$userId = $data['userid'];
		$mediatypeId = $data['mediatypeid'];
		if (empty($userId) || empty($mediatypeId)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: userid or mediatypeid is empty'));
		}
		$media_info = API::UserMedia()->get(array(
			'output' => 'extend',
			'userids' => $userId,
		));
		foreach($media_info as $mediaItem) {
			$typeId = $mediaItem['mediatypeid'];
			$mediaId = $mediaItem['mediaid'];
			if (strcmp($typeId, $mediatypeId) == 0) {
				API::User()->deleteMedia($mediaId);
			}
		}
		return array('Message' => 'Delete one type media successfully');
	}

	/**
	 * Get media address with original and new address
	 *
	 * @throws APIException if fail to get media address
	 *
	 * @param string $data['userid']
	 * @param string $data['mediatypeid']
	 * @param string $data['address']
	 *
	 * @return array about media address
	 */
	protected function GetMediaAddress($data) {
		$userId = $data['userid'];
		$mediatypeId = $data['mediatypeid'];
		$address = trim($data['address']);
		if (empty($address)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Media address is empty'));
		}
		$media_info = API::UserMedia()->get(array(
			'output' => 'extend',
			'userids' => $userId,
		));
		foreach($media_info as $mediaItem) {
			$typeId = $mediaItem['mediatypeid'];
			$mediaId = $mediaItem['mediaid'];
			if (strcmp($typeId, $mediatypeId) == 0) {
				$newAddress = $mediaItem['sendto'] . "," . $address;
				API::User()->deleteMedia($mediaId);
				return array('address' => $newAddress);
			}
		}
		return array('address' => $address);
	}

	/**
	 * Add one media to user
	 *
	 * @throws APIException if fail to add one media
	 *
	 * @param string $data['userid']
	 * @param string $data['mediatype']
	 * @param string $data['address']
	 *
	 * @return array
	 */
	protected function AddMedia($data = array()) {
		$userid['userid'] = $data['userid'];
		$media_type_name = $data['mediatype'];
		$media_address = $data['address'];
		if (empty($userid['userid']) || empty($media_type_name) || empty($media_address)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty of input parameter'));
		}

		$mediatypeid = API::MediaType()->get(array(
		    'output' => 'mediatypeid',
		    'filter' => array("description" => $media_type_name)
		    ));
		if (empty($mediatypeid)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('Unknown mediatype "%s"', $media_type_name));
		}
		$mediaInfo['userid'] = $userid['userid'];
		$mediaInfo['mediatypeid'] = $mediatypeid[0]['mediatypeid'];
		$mediaInfo['address'] = $media_address;
		$AllMediaAddress = self::GetMediaAddress($mediaInfo);
		self::DeleteOneTypeMedia($mediaInfo);

		$medias[0]['mediatypeid'] = $mediatypeid[0]['mediatypeid'];
		$medias[0]['sendto'] = $AllMediaAddress['address'];
		$medias[0]['severity'] = 63;
		$medias[0]['active'] = 0;
		$medias[0]['period'] ="1-7,00:00-24:00";
		$add_medias['users'] = $userid;
		$add_medias['medias'] = $medias;
		$action_ret = API::User()->addMedia($add_medias);
		return array('Message' => 'ADD user media successfully');
	}

	/**
	* Add mass medias to alter user
	*
	* @throw APIException if fail to add all user medias
	*
	* @param string $data['username']
	* @param string $data['accountname']
	* @param array $data['medias']
	* @param string $data['medias']['mediatype']
	* @param string $data['medias']['address']
	*
	* @return array
	*/
	public function AddAlterUserMedia($data = array()) {
		$accountname = $data['accountname'];
		$name = $data['username'];
		$username = self::TranslateAlterUserName($accountname, $name);
		$medias = zbx_toArray($data['medias']);
		if ((empty($username)) || empty($data['medias']) || (is_array($data['medias']) === false)) {
		    self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Wrong input parameter'));
		}
		$userid = API::User()->get(array(
		    'output' => 'userid',
		    'filter' => array("alias" => $username)
		    ));
		if (empty($userid)) {
		    self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The user "%s" not exist', $name));
		}

		foreach ($medias as $mediaItem) {
			if (!empty($mediaItem['mediatype'])) {
				$add_medias['userid'] = $userid[0]['userid'];
				$add_medias['mediatype'] = $mediaItem['mediatype'];
				$add_medias['address'] = $mediaItem['address'];
				self::AddMedia($add_medias);
			} else {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: User mediatype is empty'));
			}
		}
		return array('Message' => 'ADD user media successfully');
	}

	/**
	 * Delete the media address from the original user media address
	 *
	 * @throw APIException if fail to delete media address
	 *
	 * @param string $data['userid']
	 * @param string $data['mediatypeid']
	 * @param string $data['address']
	 *
	 * @return array
	 * @return param string $address - the remaining addresses of deleting address
	 * @return param interger $success - delete address success or not
	 */
	protected function DeleteAddress($data) {
		$userId = $data['userid'];
		$mediaTypeId = $data['mediatypeid'];
		$address = $data['address'];

		$mediaInfo = API::UserMedia()->get(array(
			'output' => 'extend',
			'userids' => $userId,
		));
		$addressLen = strlen($address);
		$finalAddr = "";
		$addrMatch = 0;
		foreach($mediaInfo as $mediaItem) {
			$typeId = $mediaItem['mediatypeid'];
			$sendAddr = $mediaItem['sendto'];
			if(strcmp($typeId, $mediaTypeId) == 0) {
				$addrArr = explode(",", $sendAddr);
				foreach	($addrArr as $key => $addrItem) {
					$addrItem = trim($addrItem);
					$addrArr[$key] = trim($addrItem);
					if (!empty($addrItem)) {
						if (strcmp($addrItem, $address) == 0) {
							unset($addrArr[$key]);
							$addrMatch = 1;
						}
					} else {
						unset($addrArr[$key]);
					}
				}
				$addrArr = array_values($addrArr);
				$finalAddr = implode(",", $addrArr);
				break;
			}
		}
		return array("address" => $finalAddr, "success" => $addrMatch, "deleteAddress" => $address);
	}

	/**
	 * Delete the specified medias from user
	 *
	 * @throw APIException if fail to delete the specified medias
	 *
	 * @param string $data['userid']
	 * @param string $data['mediatype']
	 * @param string $data['address']
	 *
	 * @return array
	 */
	protected function DeleteMedias($data) {
		$userId['userid'] = $data['userid'];
		$mediaTypeName = $data['mediatype'];
		$mediaAddress = $data['address'];
		$mediaArr = explode(",", $mediaAddress);
		$mediaTypeId = API::MediaType()->get(array(
		    'output' => 'mediatypeid',
		    'filter' => array("description" => $mediaTypeName)
		    ));
		if (empty($mediaTypeId)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('Unknown mediatype "%s"', $mediaTypeName));
		}
		$mediaInfo['userid'] = $data['userid'];
		$mediaInfo['mediatypeid'] = $mediaTypeId[0]['mediatypeid'];
		$arrNum = count($mediaArr);
		$emptyNum = 0;
		foreach ($mediaArr as $address) {
			$mediaInfo['address'] = trim($address);
			if (empty($mediaInfo['address'])) {
				$emptyNum++;
				continue;
			}
			$finalAddr = self::DeleteAddress($mediaInfo);
			if ($finalAddr['success'] == 0) {
				return array('Message' => 'Delete medias failed', 'success' => 0, 'deleteAddress' => $finalAddr['deleteAddress']);
			}
			if(!empty($finalAddr['address'])) {
				$mediaInfo['address'] = $finalAddr['address'];
				self::DeleteOneTypeMedia($mediaInfo);
				$mediaInfo['mediatype'] = $mediaTypeName;
				self::AddMedia($mediaInfo);
			} else if ((empty($finalAddr['address'])) && ($finalAddr['success'] == 1)){
				self::DeleteOneTypeMedia($mediaInfo);
			}
		}
		if ((($emptyNum != 0) && ($arrNum == $emptyNum)) || empty($mediaArr)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('The media adress can not be empty'));
		}
		return array('Message' => 'Delete medias successfully', 'success' => 1);
	}

	/**
	 * Delete medias form alter users
	 *
	 * @throw APIException if fail to delete medias
	 *
	 * @param string $data['username']
	 * @param string $data['accountname']
	 * @param array $data['medias']
	 * @param string $data['medias']['mediatype']
	 * @param string $data['medias']['address']
	 *
	 * @return array
	 */
	public function DeleteAlterUserMedia($data) {
		$accountname = $data['accountname'];
		$name = $data['username'];
		$username = self::TranslateAlterUserName($accountname, $name);
		$medias = zbx_toArray($data['medias']);
		if ((empty($username)) || empty($data['medias'])) {
		    self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Wrong input parameter'));
		}

		$userid = API::User()->get(array(
		    'output' => 'userid',
		    'filter' => array("alias" => $username)
		    ));
		if (empty($userid)) {
		    self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The user "%s" not exist', $name));
		}
		foreach($medias as $mediaItem) {
			if (!empty($mediaItem['mediatype'])) {
				$delete_medias['userid'] = $userid[0]['userid'];
				$delete_medias['mediatype'] = $mediaItem['mediatype'];
				$delete_medias['address'] = $mediaItem['address'];
				$delete = self::DeleteMedias($delete_medias);
				$deleteSuccess = $delete['success'];
				if ($deleteSuccess == 0) {
					self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The media address "%s" do not exist', $delete['deleteAddress']));
				}
			} else {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: User mediatype is empty'));
			}
		}
		return array('Message' => 'Delete user medias successfully');
	}

	/**
	 * Delete item/items for frontend.
	 *
	 * @param array $options
	 * @param string $options['hostname']
	 * @param array $options['items']
	 *
	 * @return array
	 */
	public function DeleteItem($options) {
		$options = zbx_toArray($options);
		if(empty($options)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Empty input parameter exist.'));
		}
		$counter = count($options);
		for($i = 0; $i < $counter; $i++) {
			$host = $options[$i];
			if(empty($host)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Empty input parameter exist.'));
			}
			$hostname = $host['hostname'];
			$items = $host['keys'];
			if(empty($hostname) || empty($items)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Empty input parameter exist.'));
			}

			/* Get hostid */
			$hostid = API::Host()->get(array(
						'output' => 'hostid',
						'filter' => array( 'host' => $hostname )));
			if(empty($hostid)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Some host does not exist.'));
			}

			/* Get all itemid */
			$items = zbx_toArray($items);
			$counter_item = count($items);
			$itemids = array();
			for($j = 0; $j < $counter_item; $j++) {
				$item_key = $items[$j];
				if(empty($item_key)) {
					self::exception(ZBX_API_ERROR_PARAMETERS, _('Empty input parameter exist.'));
				}
				$itemid = API::Item()->get(array(
							'output' => 'itemid',
							'hostids' => $hostid[0]['hostid'],
							'filter' => array('key_' => $item_key)));
				if(empty($itemid)) {
					self::exception(ZBX_API_ERROR_PARAMETERS, _s('Item with key %s does not exist.', $item_key));
				}
				$itemids[$j] = $itemid[0]['itemid'];
			}

			/* Delete items */
			$result = API::Item()->delete($itemids);
		}
		return array( 'Message' => 'Delete items successfully!');
	}

	/**
	 * Get the index value of item type in zabbix
	 *
	 * @throw APIException if fail to get item type index value
	 *
	 * @param string data
	 *
	 * @return array
	 */
	protected  function GetItemType($data) {
		$itemTypeArr = array("zabbix agent", "SNMPv1 agent", "zabbix trapper", "simple check", "SNMPv2 agent",
			"zabbix internal", "SNMPv3 agent", "zabbix agent(active)", "zabbix aggregate", "web item",
			"external check", "database monitor", "IPMI agent", "SSH agent", "TELNET agent", "calculated", "JMX agent", "SNMP trap");
		$typeSum = count($itemTypeArr);
		$itemType = $data;
		if (empty($itemType)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty item type'));
		}

		$index = 0;
		foreach ($itemTypeArr as $item) {
			if (strcmp($item, $itemType) == 0) {
				break;
			}
			$index++;
		}
		if ($index >= $typeSum) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The item type "%s" do not exist', $itemType));
		}
		return array('value' => $index);
	}

	/**
	 * Get the index of item vaule type
	 *
	 * @throw APIException if fail to get the index of item value type
	 *
	 * @param string $data
	 *
	 * @return array
	 */
	protected function GetItemValueType($data) {
		$valueType = $data;
		if (empty($valueType)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty item value type'));
		}
		$valueTypeArr = array("float", "character", "log", "unsigned", "text");
		$valueTypeNum = count($valueTypeArr);
		$index = 0;
		foreach ($valueTypeArr as $item) {
			if(strcmp($item, $valueType) == 0) {
				break;
			}
			$index++;
		}
		if ($index >= $valueTypeNum) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The item value type "%s" do not exist', $valueType));
		}
		return array('value' => $index);
	}

	/**
	 * Create item to one host
	 *
	 * @throw APIException if fail to add item
	 *
	 * @param array $data
	 * @param string $data[0]['name']
	 * @param string $data[0]['key']
	 * @param string $data[0]['hostname']
	 * @param string $data[0]['hostip']
	 * @param string $data[0]['updatetime']
	 * @param string $data[0]['itemtype']
	 * @param string $data[0]['valuetype']
	 * @param string $data[0]['units']
	 * @param string $data[0]['group']
	 *
	 * @return array
	 */
	public function CreateItem($data = array()) {
		$items = zbx_toArray($data);
		$num = count($items);

		if ($num == 0) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter'));
		}

		foreach ($items as $item) {
			$name = trim($item['name']);
			$key = trim($item['key']);
			$hostName = trim($item['hostname']);
			$hostIp = trim($item['hostip']);
			$updateTime = trim($item['updatetime']);
			$itemType = trim($item['itemtype']);
			$valueType = trim($item['valuetype']);
			$units = trim($item['units']);
			$application = trim($item['group']);
			if (empty($name) || empty($key) || empty($hostName) || empty($hostIp)
				|| empty($updateTime) || empty($itemType) || empty($valueType)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter'));
			}
			$hostId = API::host()->get(array(
				'output' => 'hostid',
				'filter' => array("host" => $hostName)
			));
			if (empty($hostId)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The host "%s" do not exist', $hostName));
			}
			$interfaceId = API::hostinterface()->get(array(
				'output' => array('interfaceid'),
				'hostid' => $hostId,
				'filter' => array("ip" => $hostIp)
			));
			if (empty($interfaceId)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The host "%s : %s" do not exist', $hostName, $hostIp));
			}
			$addItem['name'] = $name;
			$addItem['key_'] = $key;
			$addItem['hostid'] = $hostId[0]['hostid'];
			$type = self::GetItemType($itemType);
			$addItem['type'] = $type['value'];
			$type = self::GetItemValueType($valueType);
			$addItem['value_type'] = $type['value'];
			$addItem['interfaceid'] = $interfaceId[0]['interfaceid'];
			$addItem['delay'] = $updateTime;
			if (!empty($application)) {
				$applicationId = API::application()->get(array(
					'output' => 'applicationid',
					'hostids' => $hostId[0]['hostid'],
					'filter' => array("name" => $application)
				));
				if (empty($applicationId)) {
					self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The host "%s : %s" do not have application "%s"', $hostName, $hostIp, $application));
				}
				$addItem['applications'][0] = $applicationId[0]['applicationid'];
			}
			if (!empty($units)) {
				$addItem['units'] = $units;
			}
			$addItem['status'] = 0;
			$addItem['history'] = 7;
			$addItem['trends'] = 30;
			$itemId = API::item()->get(array(
				'output' => 'itemid',
				'hostids' => $hostId[0]['hostid'],
				'filter' => array("name" => $name)
			));
			if (!empty($itemId)) {
				 self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: Item "%s" already exist in host "%s"', $name, $hostName));
			}
			$ret = API::item()->create($addItem);
			unset($addItem);
		}
		return array('Message' => 'Create item successfully');
	}


	/**
	 * Create trigger to one item for a host
	 *
	 * @throw APIException if fail to add trigger
	 *
	 * @param array $data
	 * @param array $data[expr]
	 * @param array $data[name]
	 *
	 * @return array
	 */
	public function CreateTrigger($data = array()) {
		$triggers = zbx_toArray($data);
		if (empty($triggers)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: no trigger to be created'));
		}
		foreach ($triggers as $elem) {
			$expr = trim($elem['expr']);
			$des = trim($elem['name']);
			if (empty($des) || empty($expr)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter.'));
			}
			$trigger['output'] = 'triggerid';
			$trigger['description'] = $des;
			$trigger['expression'] = $expr;
			$trigger['priority'] = 4;
			$trigger['status'] = 0;
			$ret = API::trigger()->create($trigger);
		}
		return array('Message' => 'Create trigger successfully', $ret);
	}

	/**
	 * Delete trigger from a host
	 *
	 * @throw APIException if fail to delete trigger
	 *
	 * @param array $data
	 * @param array $data['hostname']
	 * @param array $data['name']
	 *
	 * @return array
	 */
	public function DeleteTrigger($data = array()) {
		$triggers = zbx_toArray($data);
		if (empty($triggers)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: no trigger to be deleted'));
		}
		foreach ($triggers as $elem) {
			$hostname = trim($elem['hostname']);
			$des = trim($elem['name']);
			if (empty($des) || empty($hostname)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter.'));
			}
			$trigger['host'] = $hostname;
			$trigger['description'] = $des;
			$ret = API::trigger()->get(array('filter' => $trigger));
			$ret = API::trigger()->delete(array($ret[0]['triggerid']));
		}
		return array('Message' => 'Delete trigger successfully', $ret);
	}

	/**
	 * Create action for one or more triggers
	 *
	 * @throw APIException if fail to create action
	 *
	 * @param array $data
	 * @param string $data['name']
	 * @param string $data['accountname']
	 * @param string/array $data['triggerid']
	 * @param string/array $data['alterusers']
	 *
	 * @return array
	 */
	public function CreateAction($data=array()) {
		$action['name']	= trim($data['name']);
		if (empty($action['name'])) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have action name'));
		}
		$action['eventsource'] = 0; #trigger event
		$action['esc_period'] = 60; #update 60s
		$action['status'] = 0; #enabled

		$action['def_shortdata'] = "[故障告警]-[{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
		$action['def_longdata'] = "发生时间：{EVENT.DATE} {EVENT.TIME}\r\n服务器IP：{HOST.IP}\r\n告警类型：故障告警\r\n告警级别：重要\r\n监控项与阈值：{TRIGGER.NAME} {TRIGGER.DESCRIPTION}\r\n告警详情：平均值: {ITEM.VALUE}";
		$action['recovery_msg'] = 1;
		$action['r_shortdata'] = "[故障恢复]-[{DATE} {TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
		$action['r_longdata'] = "发生时间：{EVENT.DATE} {EVENT.TIME}\r\n解除时间：{DATE} {TIME}\r\n服务器IP：{HOST.IP}\r\n告警类型：故障恢复\r\n告警级别：一般\r\n监控项与阈值：{TRIGGER.NAME} {TRIGGER.DESCRIPTION}";

		$action['evaltype'] = 0; #and/or
		$conditions[0]['conditiontype'] = 5; #trigger value
		$conditions[0]['operator'] = 0;
		$conditions[0]['value'] = 1;
		$triggerIds = zbx_toArray($data['triggerid']);
		$i = 1;
		foreach ($triggerIds as $triggerId) {
			$id = trim($triggerId);
			if (empty($id)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The %d trigger is empty', $i));
			}
			$conditions[$i]['conditiontype'] = 2; #trigger
			$conditions[$i]['operator'] = 0; #=
			$conditions[$i]['value'] = $triggerId; #trigger id
			$i++;
		}
		if ($i == 1) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have any trigger'));
		}
		$action['conditions'] = $conditions;

		$mailMediaType = "Alert By Email";
		$operations[0]['operationtype'] = 0; #send message
		$operations[0]['esc_period'] = 60; #60s
		$operations[0]['esc_step_from'] = 1;
		$operations[0]['esc_step_to'] = 1;
		$operations[0]['evaltype'] = 0; #and/or
		$opmessage['default_msg'] = 1; #
		$mailMediaTypeId = API::MediaType()->get(array(
			'output' => 'mediatypeid',
			'filter' => array("description" => $mailMediaType)
		));
		if (empty($mailMediaTypeId)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s("Do not have media type Alert By Email"));
		}
		$opmessage['mediatypeid'] = $mailMediaTypeId[0]['mediatypeid']; #mediatypeid
		$operations[0]['opmessage'] = $opmessage;
		$accountname = $data['accountname'];
		$users = zbx_toArray($data['alterusers']);
		$userIds = array(); $i = 0;
		foreach ($users as $user) {
			$alterusername = self::TranslateAlterUserName($accountname, $user);
			$userIds[$i] = API::User()->get(array(
				'output' => 'userid',
				'filter' => array("alias" =>$alterusername)
			));
			$i++;
		}
		if ($i == 0) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have any user to receive information'));
		}
		$userId = array(); $i = 0;
		foreach($userIds as $id) {
			$userId[$i] = $id[0];
			$i++;
		}
		$operations[0]['opmessage_usr'] = $userId;

		$phoneMediaType = "Alert By Phone";
		$operations[1]['operationtype'] = 0; #send message
		$operations[1]['esc_period'] = 60; #60s
		$operations[1]['esc_step_from'] = 1;
		$operations[1]['esc_step_to'] = 1;
		$operations[1]['evaltype'] = 0; #and/or
		$opmessage['default_msg'] = 0; #
		$opmessage['subject'] = "[{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}][金山云]";
		$opmessage['message'] = "[{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}][金山云]";
		$phoneMediaTypeId = API::MediaType()->get(array(
			'output' => 'mediatypeid',
			'filter' => array("description" => $phoneMediaType)
		));
		if (empty($phoneMediaTypeId)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s("Do not have media type Alert By Phone"));
		}
		$opmessage['mediatypeid'] = $phoneMediaTypeId[0]['mediatypeid']; #mediatypeid
		$operations[1]['opmessage'] = $opmessage;
		$operations[1]['opmessage_usr'] = $userId;
		$action['operations'] = $operations;
		$ret = API::Action()->create($action);

		return array('Message' => 'Create action successfully');
	}

	/**
	 * Delete one or more actions
	 *
	 * @throw APIException if fail to delete action
	 *
	 * @param array $data
	 * @param string/array $data['name']
	 *
	 * @return array
	 */
	public function DeleteAction($data=array()) {
		$actionNames = zbx_toArray($data['name']);
		$i = 0;
		$actionIds = array();
		foreach ($actionNames as $actionName) {
			$name = trim($actionName);
			if (empty($name)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s("The %d actionname is empty", ($i+1)));
			}
			$actionId = API::Action()->get(array(
				'output' => 'actionids',
				'filter' => array("name" => $actionName)
			));
			$actionIds[$i] = $actionId[0]['actionid'];
			$i++;
		}
		$ret = API::Action()->delete($actionIds);
		return array('Message' => 'Delete action successfully');
	}

	protected function GetHostGroup($accountname) {
		$accountName = trim($accountname);
		if (empty($accountName)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter account name.'));
		}
		return $accountname.'_hostgroup';
	}

	protected function GetUserGroup($accountname) {
		$accountName = trim($accountname);
		if (empty($accountName)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter account name.'));
		}
		return $accountname.'_usergroup';
	}

	/**
	 * Get all alerts of a hostgroup
	 *
	 * @throw APIException if fail to get alert
	 *
	 * @param array $data
	 * @param string $data['accountname']
	 *
	 * @return array include sendto, message, subject
	 */
	public function GetAlert($data=array()) {
		if (empty($data['accountname'])) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have account name'));
		}
		/* Get host group id */
		$hostgroup = self::GetHostGroup(trim($data['accountname']));
		$hostg_param['output'] = 'groupid';
		$hostg_param['filter'] = array('name' => array($hostgroup));
		$hostgid = API::Hostgroup()->get($hostg_param);

		if (empty($hostgid[0])) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Cant find the user'));
		}
		/* Get alerts */
		$alert_param['output'] = array('sendto', 'subject', 'message');
		$alert_param['groupids'] = $hostgid[0]['groupid'];
		$alert_param['filter'] = array('status' => '1');
		$alerts = API::Alert()->get($alert_param);

		return $alerts;
	}

	/**
	 * Translate the alter user name to a unique string
	 *
	 * @param string $parent
	 * @param string $name
	 *
	 * return the unique string
	 */
	protected function TranslateAlterUserName($accountname, $name) {
		$userName = trim($name);
		$accountName = trim($accountname);
		if (empty($userName) || empty($accountName)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter.'));
		}
		$alterName = "__"."alter___".$accountName."___".$userName;
		return $alterName;
	}

	/**
	 * Create alter user to receive trigger altering information
	 *
	 * @param array $data
	 * @param string $data['username']
	 * @param string $data['accountname']
	 * @param string $data['phone']
	 * @param string $data['email']
	 *
	 * return array
	 */
	public function CreateAlterUser($data=array()) {
		$accountName = trim($data['accountname']);
		$userName = self::TranslateAlterUserName($accountName, $data['username']);
		if (empty($userName)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter.'));
		}
		$userGroup = self::GetUserGroup($accountName);
		$userGroupIdArr = API::UserGroup()->get(array(
			'output' => 'usrgrpid',
			'filter' => array("name" => $userGroup)
		));
		if (empty($userGroupIdArr)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: account %s not exit.', $accountName));
		}
		$userGroupId = $userGroupIdArr[0];
		$user['usrgrps'] = $userGroupId;
		# get mediatype id
		$emailMediaType = API::MediaType()->get(array(
						'output' => 'mediatypeid',
						'filter' => array("description" => "Alert By Email")
						));
		$phoneMediaType = API::MediaType()->get(array(
						'output' => 'mediatypeid',
						'filter' => array("description" => "Alert By Phone")
						));
		if (empty($emailMediaType) || empty($phoneMediaType)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Alert By Email or Alert By Phone not exit'));
		}
		$phone = trim($data['phone']);
		$email = trim($data['email']);
		$userMedias[0]['mediatypeid'] = $emailMediaType[0]['mediatypeid'];
		$userMedias[0]['sendto'] = $email;
		$userMedias[0]['active'] = 0;
		$userMedias[0]['severity'] = 63;
		$userMedias[0]['period'] = "1-7,00:00-24:00";
		$userMedias[1]['mediatypeid'] = $phoneMediaType[0]['mediatypeid'];
		$userMedias[1]['sendto'] = $phone;
		$userMedias[1]['active'] = 0;
		$userMedias[1]['severity'] = 63;
		$userMedias[1]['period'] = "1-7,00:00-24:00";
		$user['user_medias'] = $userMedias;
		$user['type'] = 1; #Zabbix user
		$user['alias'] = $userName;
		$user['passwd'] = "kingSOFT!@#kingsoft.com123";
		$user_ret = API::User()->create($user);
		return array('Message' => 'Create Alter user Successfully!');
	}

	/**
	 * Delete alter user from front end
	 *
	 * @param array $data
	 * @param string $data['accountname']
	 * @param string $data['username']
	 *
	 * @return array
	 */
	public function DeleteAlterUser($data=array()) {
		$accountName = trim($data['accountname']);
		$userName = self::TranslateAlterUserName($accountName, $data['username']);
		if (empty($userName)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Empty input parameter.'));
		}
		$user =  API::User()->get(array(
			'output' => 'userid',
			'filter' => array('alias' => $userName)
		));
		if (empty($user)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: alter user %s not exit', $data['username']));
		}
		$userId = array($user[0]['userid']);
		$ret = API::User()->delete($userId);
		return array('Message' => 'Delete Alter user Successfully!');
	}

	/**
	 * Get the sum hosts on one server
	 *
	 * @param empty array $data
	 *
	 * @return hosts number
	 */
	public function GetServerHosts($data) {
		$proxys = API::Proxy()->get(array(
		    'selectHosts' => 'extend'
		));
		$proxy_num = count($proxys);
		$hosts_num = 0;
		for ($i = 0; $i < $proxy_num; $i++) {
		    $hosts = $proxys[$i]['hosts'];
		    $hosts_num = $hosts_num + count($hosts);
		}
		return $hosts_num;
		}

	/**
	* Create action for one or more triggers
	*
	* @throw APIException if fail to create action
	*
	* @param array $data
	* @param string $data['name']
	* @param string $data['accountname']
	* @param string/array $data['triggerid']
	* @param string/array $data['alterusers']
	* @param integer $data['recovery']
	* @return array
	*/
	public function CreateSMSAction($data=array()) {
		$action['name']	= trim($data['name']);
		if (empty($action['name'])) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have action name'));
		}
		$action['eventsource'] = 0; #trigger event
		$action['esc_period'] = 60; #update 60s
		$action['status'] = 0; #enabled
		$action['def_shortdata'] = "[故障告警]-[{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
		$action['def_longdata'] = "[发生时间]：[{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]\r\n";
		$action['recovery_msg'] = $data['recovery'];
		$action['r_shortdata'] = "[故障恢复]-[{DATE} {TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
		$action['r_longdata'] = "发生时间： [{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
		$action['evaltype'] = 0; #and/or
		$conditions[0]['conditiontype'] = 5; #trigger value
		$conditions[0]['operator'] = 0;
		$conditions[0]['value'] = 1;
		$triggerIds = zbx_toArray($data['triggerid']);
		$i = 1;
		foreach ($triggerIds as $triggerId) {
			$id = trim($triggerId);
			if (empty($id)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The %d trigger is empty', $i));
			}
			$conditions[$i]['conditiontype'] = 2; #trigger
			$conditions[$i]['operator'] = 0; #=
			$conditions[$i]['value'] = $triggerId; #trigger id
			$i++;
		}
		if ($i == 1) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have any trigger'));
		}
		$action['conditions'] = $conditions;
		$MediaTypes = "Alert By Phone";
		$operations[0]['operationtype'] = 0; #send message
		$operations[0]['esc_period'] = 60; #60s
		$operations[0]['esc_step_from'] = 1;
		$operations[0]['esc_step_to'] = 1;
		$operations[0]['evaltype'] = 0; #and/or
		$opmessage['default_msg'] = 1; #
		$mailMediaTypeId = API::MediaType()->get(array(
			'output' => 'mediatypeid',
			'filter' => array("description" => $MediaTypes)
		));
		if (empty($mailMediaTypeId)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s("Do not have media type"));
		}
		$opmessage['mediatypeid'] = $mailMediaTypeId[0]['mediatypeid']; #mediatypeid
		$operations[0]['opmessage'] = $opmessage;
		$accountname = $data['accountname'];
		$users = zbx_toArray($data['alterusers']);
		$userIds = array(); $i = 0;
		foreach ($users as $user) {
			$alterusername = self::TranslateAlterUserName($accountname, $user);
			$userIds[$i] = API::User()->get(array(
				'output' => 'userid',
				'filter' => array("alias" =>$alterusername)
			));
			$i++;
		}
		if ($i == 0) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have any user to receive information'));
		}
		$userId = array(); $i = 0;
		foreach($userIds as $id) {
			$userId[$i] = $id[0];
			$i++;
		}
		$operations[0]['opmessage_usr'] = $userId;
		$action['operations'] = $operations;
		$ret = API::Action()->create($action);
		return array('Message' => 'Create action successfully');
	}

	/**
	 * Create action for trigger to send email
	 *
	 * @throw APIException if fail to create action
	 *
	 * @param array $data
	 * @param string $data['name']
	 * @param string $data['accountname']
	 * @param string/array $data['triggerid']
	 * @param string/array $data['alterusers']
	 * @param intr $data['recovery']
	 *
	 * @return array
	 */
	public function CreateEmailAction($data=array()) {
		$action['name']	= trim($data['name']);
		if (empty($action['name'])) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have action name'));
		}
		$action['eventsource'] = 0; #trigger event
		$action['esc_period'] = 60; #update 60s
		$action['status'] = 0; #enabled

		$action['def_shortdata'] = "[故障告警]-[{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
		$action['def_longdata'] = "发生时间：{EVENT.DATE} {EVENT.TIME}\r\n服务器IP：{HOST.IP}\r\n告警类型：故障告警\r\n告警级别：重要\r\n监控项与阈值：{TRIGGER.NAME} {TRIGGER.DESCRIPTION}\r\n告警详情：平均值: {ITEM.VALUE}";
		#$action['recovery_msg'] = 1;
		$action['recovery_msg'] = $data['recovery'];
		$action['r_shortdata'] = "[故障恢复]-[{DATE} {TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
		$action['r_longdata'] = "发生时间：{EVENT.DATE} {EVENT.TIME}\r\n解除时间：{DATE} {TIME}\r\n服务器IP：{HOST.IP}\r\n告警类型：故障恢复\r\n告警级别：一般\r\n监控项与阈值：{TRIGGER.NAME} {TRIGGER.DESCRIPTION}";

		$action['evaltype'] = 0; #and/or
		$conditions[0]['conditiontype'] = 5; #trigger value
		$conditions[0]['operator'] = 0;
		$conditions[0]['value'] = 1;
		$triggerIds = zbx_toArray($data['triggerid']);
		$i = 1;
		foreach ($triggerIds as $triggerId) {
			$id = trim($triggerId);
			if (empty($id)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: The %d trigger is empty', $i));
			}
			$conditions[$i]['conditiontype'] = 2; #trigger
			$conditions[$i]['operator'] = 0; #=
			$conditions[$i]['value'] = string($triggerId); #trigger id
			$i++;
		}
		if ($i == 1) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have any trigger'));
		}
		$action['conditions'] = $conditions;

		$mailMediaType = "Alert By Email";
		$operations[0]['operationtype'] = 0; #send message
		$operations[0]['esc_period'] = 60; #60s
		$operations[0]['esc_step_from'] = 1;
		$operations[0]['esc_step_to'] = 1;
		$operations[0]['evaltype'] = 0; #and/or
		$opmessage['default_msg'] = 1; #
		$mailMediaTypeId = API::MediaType()->get(array(
			'output' => 'mediatypeid',
			'filter' => array("description" => $mailMediaType)
		));
		if (empty($mailMediaTypeId)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _s("Do not have media type Alert By Email"));
		}
		$opmessage['mediatypeid'] = $mailMediaTypeId[0]['mediatypeid']; #mediatypeid
		$operations[0]['opmessage'] = $opmessage;
		$accountname = $data['accountname'];
		$users = zbx_toArray($data['alterusers']);
		$userIds = array(); $i = 0;
		foreach ($users as $user) {
			$alterusername = self::TranslateAlterUserName($accountname, $user);
			$userIds[$i] = API::User()->get(array(
				'output' => 'userid',
				'filter' => array("alias" =>$alterusername)
			));
			$i++;
		}
		if ($i == 0) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have any user to receive information'));
		}
		$userId = array(); $i = 0;
		foreach($userIds as $id) {
			$userId[$i] = $id[0];
			$i++;
		}
		$operations[0]['opmessage_usr'] = $userId;
		$action['operations'] = $operations;
		$ret = API::Action()->create($action);

		return array('Message' => 'Create action successfully');
	}

	/**
	 * delete the empty element in array
	 *
	 * @param array $data
	 *
	 * @return array about deleting elements
	 */
	protected function DeleteEmptyElem($data=array()) {
		$arr = $data;
		$i = 0;
		foreach ($arr as $element) {
			$elem = trim($element);
			if (empty($elem)) {
				unset($arr[$i]);
			}
			$i++;
		}
		return $arr;
	}

	/**
	 * Create alert action about trigger
	 *
	 * @param array $data
	 * @param string $data[accountname]
	 * @param string/array $data[triggerid]
	 * @param object $data[alerusers]
	 * @param string $data[mailalertusers]
	 * @param string $data[smsalertusers]
	 *
	 * @return array about create information
	 */
	protected function CreateAlertAction($data=array()) {
		$alertusers = $data['alertusers'];
		$emailalertusers = trim($alertusers['mailalertusers']);
		$phonealertusers = trim($alertusers['smsalertusers']);
		$param = array();
		$param['accountname'] = $data['accountname'];
		$param['triggerid'] = $data['triggerid'];
		if (empty($emailalertusers) && empty($phonealertusers)) {
			$ret = API::trigger()->delete($triggerId);
			self::exception(ZBX_API_ERROR_PARAMETERS, _('No alerter user to recieve alerting information'));
		}
		$empty_users_type_num = 0;
		if (!empty($emailalertusers)) {
			$emailusers = explode(',', $emailalertusers);
			$users = self::DeleteEmptyElem($emailusers);
			if (empty($users)) {
				$empty_users_type_num++;
			} else {
				$param['name'] = $data['name']."_mail_action";
				$param['alterusers'] = $users;
				$param['recovery'] = 1;
				$ret = self::CreateEmailAction($param);
			}
		}
		if (!empty($phonealertusers)) {
			$phoneusers = explode(',', $phonealertusers);
			$users = self::DeleteEmptyElem($phoneusers);
			if (empty($users)) {
				$empty_users_type_num++;
			} else {
				$param['name'] = $data['name']."_sms_action";
				$param['alterusers'] = $users;
				$param['recovey'] = 0;
				$ret = self::CreateSMSAction($param);
			}
		}
		if ($empty_users_type_num == 2) {
			API::trigger()->delete($triggerId);
			self::exception(ZBX_API_ERROR_PARAMETERS, _('No alerter user to recieve alerting information'));
		}
		return array('Message'=>'Create aleert action successfully');
	}

	/**
	 * Create alert rules about trigger and action
	 *
	 * @param array $data
	 * @param string $data[triggername]
	 * @param string $data[triggeralias]
	 * @param string $data[expr]
	 * @param object $data[alertusers]
	 * @param string $data[mailalertusers]
	 * @param string $data[smsalertusers]
	 *
	 * @return array about create information
	 */
	public function CreateAlertRules($data=array())	{
		$rules = zbx_toArray($data);
		if (empty($rules)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('No alert rules to create'));
		}
		foreach ($rules as $rule) {
			/*create trigger*/
			$triggername = trim($rule['triggername']);
			$expr = trim($rule['expr']);
			if (empty($triggername) || empty($expr)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('No trigger parameter: triggername or expr'));
			}
			$trigger['name'] = $triggername;
			$trigger['expr'] = $expr;
			$ret = self::CreateTrigger($trigger);
			#$triggerId = $ret[0]['triggerids'][0];
			$triggerId = $ret[0]['triggerids'];
			unset($triggername);unset($expr);
			/*create alert actions*/
			if (empty($rule['alertusers'])) {
				$ret = API::trigger()->delete($triggerId);
				self::exception(ZBX_API_ERROR_PARAMETERS, _('No alert users to revieve information'));
			}
			$param = array();
			$param['accountname'] = $rule['accountname'];
			$param['triggerid'] = $triggerId;
			$param['alertusers'] = $rule['alertusers'];
			$param['name'] = $rule['triggeralias'];
			$ret = self::CreateAlertAction($param);
			unset($param);
		}
		return array('Message' => 'Create Alert rules successfully');
	}

	/**
	 * Delete alert action about trigger
	 *
	 * @param array $data
	 * @param string $data[triggeralias]
	 *
	 * @return array about deleting information
	 */
	protected function DeleteAlertAction($data=array()) {
		$triggeralias = $data;
		if (empty($triggeralias)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: no alias about trigger'));
		}
		/*delete email action */
		$emailAction = $triggeralias."_mail_action";
		/*delete sms action */
		$smsAction = $triggeralias."_sms_action";
		$actionNames = array($emailAction, $smsAction);
		$actionIds = array();
		$i = 0;
		foreach ($actionNames as $actionName) {
			$actionId = API::Action()->get(array(
				'output' => 'actionids',
				'filter' => array("name" => $actionName)
			));
			if (!empty($actionId)) {
				$actionIds[$i] = $actionId[0]['actionid'];
				$i++;
			}
		}
		if (!empty($actionIds)) {
			$ret = API::Action()->delete($actionIds);
		}
		return array('Message' => 'Delete alert action successfully');
	}

	/**
	 * Delete alert rules about trigger and action
	 *
	 * @param array $data
	 * @param string $data[triggername]
	 * @param string $data[hostname]
	 * @param string $data[triggeralias]
	 *
	 * @return array about create information
	 */
	public function DeleteAlertRules($data=array()) {
		$rules = zbx_toArray($data);
		if (empty($rules)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('No alert rules to delete'));
		}
		foreach ($rules as $rule) {
			/* delete actions */
			$triggeralias = $rule['triggeralias'];
			$ret = self::DeleteAlertAction($triggeralias);
			/* delete triggers */
			$trigger = array();
			$trigger['hostname'] = $rule['hostname'];
			$trigger['name'] = $rule['triggername'];
			$ret = self::DeleteTrigger($trigger);
			unset($trigger);unset($triggeralias);
		}
		return array('Message' => 'Delete alert rules successfully');
	}

	/**
	 * Get Id of host group
	 * @param string $groupName
	 *
	 * @return array of group id
	 **/
	protected function GetHostGroupId($groupName){
		if (empty($groupName)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Not have host group name parameter'));
		}
		$hostGroup['output'] = 'groupid';
		$hostGroup['filter'] = array('name' => array($groupName));
		$hostGroupId = API::Hostgroup()->get($hostGroup);
		if (empty($hostGroupId)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: Do not have the host group %s', $groupName));
		}

		return array('Id' => $hostGroupId[0]['groupid']);
	}

	/**
	 * Create actions for one host group
	 *
	 * @param array $data
	 * @param string $data[accountname]
	 *
	 * @return array about create host group action
	 **/
	public function CreateHostGroupAction($data=array()) {
		$actions = zbx_toArray($data);
		if (empty($actions)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('No action to create'));
		}
		foreach($actions as $elem) {
			$accountname = trim($elem['accountname']);
			if (empty($accountname)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _('Error: the acctount name is empty'));
			}
			$action['name'] = $accountname."_host_group_action";
			$action['eventsource'] = 0; #trigger event
			$action['esc_period'] = 60; #update 60s
			$action['status'] = 0; #enabled

			$action['def_shortdata'] = "[故障告警]-[{EVENT.DATE} {EVENT.TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
			$action['def_longdata'] = "发生时间：{EVENT.DATE} {EVENT.TIME}\r\n服务器IP：{HOST.IP}\r\n告警类型：故障告警\r\n告警级别：重要\r\n监控项与阈值：{TRIGGER.NAME} {TRIGGER.DESCRIPTION}\r\n告警详情：{ITEM.VALUE}";
			$action['recovery_msg'] = 1;
			$action['r_shortdata'] = "[故障恢复]-[{DATE} {TIME}]-[{HOST.IP}]-[{TRIGGER.NAME}]";
			$action['r_longdata'] = "发生时间：{EVENT.DATE} {EVENT.TIME}\r\n解除时间：{DATE} {TIME}\r\n服务器IP：{HOST.IP}\r\n告警类型：故障恢复\r\n告警级别：一般\r\n监控项与阈值：{TRIGGER.NAME} {TRIGGER.DESCRIPTION}";

			$action['evaltype'] = 0; #and/or
			$conditions[0]['conditiontype'] = 5; #trigger value
			$conditions[0]['operator'] = 0;
			$conditions[0]['value'] = "1";

			$hostGroupName = self::GetHostGroup($elem['accountname']);
			$hostGroupId = self::GetHostGroupId($hostGroupName);
			$conditions[1]['conditiontype'] = 0; #host group
			$conditions[1]['operator'] = 0;
			$conditions[1]['value'] = (string)($hostGroupId['Id']);
			$action['conditions'] = $conditions;

			$userGroup = self::GetUserGroup($elem['accountname']);
			$userGroupIdArr = API::UserGroup()->get(array(
				'output' => 'usrgrpid',
				'filter' => array("name" => $userGroup)
			));
			if (empty($userGroupIdArr)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s('Error: account %s not exit.', $elem['accountname']));
			}
			$userGroupId = $userGroupIdArr;

			$mailMediaType = "Alert By Email";
			$operations[0]['operationtype'] = 0; #send message
			$operations[0]['esc_period'] = 60; #60s
			$operations[0]['esc_step_from'] = 1;
			$operations[0]['esc_step_to'] = 1;
			$operations[0]['evaltype'] = 0; #and/or
			$opmessage['default_msg'] = 1; # use the defaut message text and subject
			$mailMediaTypeId = API::MediaType()->get(array(
				'output' => 'mediatypeid',
				'filter' => array("description" => $mailMediaType)
			));
			if (empty($mailMediaTypeId)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s("Do not have media type Alert By Email"));
			}
			$opmessage['mediatypeid'] = $mailMediaTypeId[0]['mediatypeid']; #mediatypeid
			$operations[0]['opmessage'] = $opmessage;
			$operations[0]['opmessage_grp'] = $userGroupId;

			$phoneMediaType = "Alert By Phone";
			$operations[1]['operationtype'] = 0; #send message
			$operations[1]['esc_period'] = 60; #60s
			$operations[1]['esc_step_from'] = 1;
			$operations[1]['esc_step_to'] = 1;
			$operations[1]['evaltype'] = 0; #and/or
			$opmessage['default_msg'] = 1; # use the default message text and subject
			$phoneMediaTypeId = API::MediaType()->get(array(
				'output' => 'mediatypeid',
				'filter' => array("description" => $phoneMediaType)
			));
			if (empty($phoneMediaTypeId)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _s("Do not have media type Alert By Phone"));
			}
			$opmessage['mediatypeid'] = $phoneMediaTypeId[0]['mediatypeid']; #mediatypeid
			$operations[1]['opmessage'] = $opmessage;
			$operations[1]['opmessage_grp'] = $userGroupId;
			$action['operations'] = $operations;
			$ret = API::Action()->create($action);
		}
		return array('Message' => 'Create actions successfully');
	}

	/**
	* Delete action about one host group
	*
	* @param array $data
	* @param string $data[accountname]
	*
	* @return array about delete action information
	**/
	public function DeleteHostGroupAction($data) {
		$actions = zbx_toArray($data);
		if (empty($actions)) {
			self::exception(ZBX_API_ERROR_PARAMETERS, _('No action to delete'));
		}

		$i = 0;
		$actionIds = array();
		foreach ($actions as $elem) {
			$accountName = trim($elem['accountname']);
			if (empty($accountName)) {
				self::exception(ZBX_API_ERROR_PARAMETERS, _("The action accountname is empty"));
			}
			$actionName = $accountName."_host_group_action";
			$actionId = API::Action()->get(array(
				'output' => 'actionids',
				'filter' => array("name" => $actionName)
			));
			$actionIds[$i] = $actionId[0]['actionid'];
			$i++;
		}
		$ret = API::Action()->delete($actionIds);
		return array('Message' => 'Delete actions successfully');
	}
}
